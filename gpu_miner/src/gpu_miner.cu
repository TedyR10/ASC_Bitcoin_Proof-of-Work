// Copyright Theodor-Ioan Rolea, 333CA, 2024
#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

// CUDA implementation for strcat
__device__ void d_strcat(char* dest, const char* src) {
    int dest_len = 0;
    while (dest[dest_len] != '\0') {
        dest_len++;
    }
    int src_len = 0;
    while ((dest[dest_len + src_len] = src[src_len]) != '\0') {
        src_len++;
    }
}

__global__ void findNonce(BYTE* prev_block_hash, BYTE* top_hash, BYTE* block_hash, BYTE* difficulty, uint64_t* found_nonce, uint64_t *ok) {
	// Check if nonce has been found
	if (ok[0] == 1) return;

	// Calculate nonce
	uint64_t nonce = blockIdx.x * blockDim.x + threadIdx.x + 1;

	// Check if nonce is valid
    if (nonce > MAX_NONCE) return;

	// Initialize block content
    BYTE block_content[BLOCK_SIZE];
    d_strcpy((char*)block_content, (const char*)prev_block_hash);
    d_strcat((char*)block_content, (const char*)top_hash);

    char nonce_string[NONCE_SIZE];
    intToString(nonce, nonce_string);
    d_strcat((char*)block_content, nonce_string);

	// Calculate hash
    BYTE temp_hash[SHA256_HASH_SIZE];
    apply_sha256(block_content, d_strlen((const char*)block_content), temp_hash, 1);


	// Check if hash is valid
    if (compare_hashes(temp_hash, difficulty) <= 0) {
		// Using lock to prevent
		// multiple threads from writing to the same memory location
        atomicExch((unsigned long long*)found_nonce, (unsigned long long)nonce);

		// Set ok to 1 to stop other threads
		// once nonce has been found
		ok[0] = 1;

		// Copy hash to block_hash
        d_strcpy((char*)block_hash, (const char*)temp_hash);
    }
}

int main(int argc, char **argv) {
	BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
			tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
			tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE], block_content[BLOCK_SIZE];
	BYTE block_hash[SHA256_HASH_SIZE] = "0000000000000000000000000000000000000000000000000000000000000000";
	BYTE *d_prev_block_hash, *d_top_hash, *d_block_hash, *d_difficulty;
    uint64_t *d_found_nonce;

	// Top hash
	apply_sha256(tx1, strlen((const char*)tx1), hashed_tx1, 1);
	apply_sha256(tx2, strlen((const char*)tx2), hashed_tx2, 1);
	apply_sha256(tx3, strlen((const char*)tx3), hashed_tx3, 1);
	apply_sha256(tx4, strlen((const char*)tx4), hashed_tx4, 1);
	strcpy((char *)tx12, (const char *)hashed_tx1);
	strcat((char *)tx12, (const char *)hashed_tx2);
	apply_sha256(tx12, strlen((const char*)tx12), hashed_tx12, 1);
	strcpy((char *)tx34, (const char *)hashed_tx3);
	strcat((char *)tx34, (const char *)hashed_tx4);
	apply_sha256(tx34, strlen((const char*)tx34), hashed_tx34, 1);
	strcpy((char *)tx1234, (const char *)hashed_tx12);
	strcat((char *)tx1234, (const char *)hashed_tx34);
	apply_sha256(tx1234, strlen((const char*)tx34), top_hash, 1);

	strcpy((char*)block_content, (const char*)prev_block_hash);
	strcat((char*)block_content, (const char*)top_hash);
    
	// Initialize gpu fields
    cudaMalloc(&d_prev_block_hash, SHA256_HASH_SIZE);
    cudaMalloc(&d_top_hash, SHA256_HASH_SIZE);
    cudaMalloc(&d_block_hash, SHA256_HASH_SIZE);
    cudaMalloc(&d_difficulty, SHA256_HASH_SIZE);
    cudaMalloc(&d_found_nonce, sizeof(uint64_t));

    uint64_t found_nonce = 0;
    
	// Copy data to gpu memory
    cudaMemcpy(d_prev_block_hash, prev_block_hash, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_top_hash, top_hash, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_block_hash, block_hash, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_difficulty, difficulty_5_zeros, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_found_nonce, &found_nonce, sizeof(uint64_t), cudaMemcpyHostToDevice);

	// Initialize block and threads
    int blockSize = 256;
    int numBlocks = (MAX_NONCE / blockSize) + 1;

	// Initialize the ok flag
	int ok[1] = {0};
	uint64_t *d_ok;
	cudaMalloc(&d_ok, sizeof(uint64_t));
	cudaMemcpy(d_ok, ok, sizeof(uint64_t), cudaMemcpyHostToDevice);

	cudaEvent_t start, stop;
    startTiming(&start, &stop);
    
    findNonce<<<numBlocks, blockSize>>>(d_prev_block_hash, d_top_hash, d_block_hash, d_difficulty, d_found_nonce, d_ok);

    cudaDeviceSynchronize();

	float seconds = stopTiming(&start, &stop);

	// Copy data from gpu memory
    cudaMemcpy(block_hash, d_block_hash, SHA256_HASH_SIZE, cudaMemcpyDeviceToHost);
    cudaMemcpy(&found_nonce, d_found_nonce, sizeof(uint64_t), cudaMemcpyDeviceToHost);
    
	printResult(block_hash, found_nonce, seconds);

	// Free everything
    cudaFree(d_prev_block_hash);
    cudaFree(d_top_hash);
    cudaFree(d_block_hash);
    cudaFree(d_difficulty);
    cudaFree(d_found_nonce);

	return 0;
}
