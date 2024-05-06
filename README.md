**Name: Theodor-Ioan Rolea**

**Group: 333CA**

# HW2 ASC - Bitcoin Proof of Work Consensus Algorithm

## Overview

This project aims to implement the Bitcoin Proof of Work consensus algorithm on
a GPU using CUDA. The proof-of-work algorithm is a critical component in
cryptocurrency systems like Bitcoin, where it is used to validate transactions
and create new blocks in the blockchain.

In this assignment, the objective is to find a `nonce` value that, when
concatenated with certain inputs and hashed, results in a SHA-256 hash with a
specific number of leading zeros (indicating difficulty). The given code seeks
to find this nonce in a parallelized manner to optimize for speed.

***

# Code Structure

The code is divided into two parts:

- **findNonce**: This is the core of the GPU implementation. It uses a parallel
approach to find the correct nonce by computing SHA-256 hashes and checking
against a difficulty level until a valid nonce is found.

- **main**: This is the entry point for the program. It initializes the
necessary data on the host and then allocates memory on the GPU. It launches
the `findNonce` kernel to find the correct nonce, synchronizes the GPU, and
retrieves the results. Finally, it prints the result, including the found nonce,
 block hash, and execution time.

***

# Development Insights

- **Parallelization**: To improve performance, I have opted to use a large
number of blocks and threads to maximize the number of parallel computations
executed simultaneously. This approach allows the GPU to process a large number
of hashes concurrently, significantly reducing the time required to find the
correct nonce.

- **Optimization and Error Prevention**: To further enhance speed, atomic
operations were used to ensure synchronization and avoid conflicts when multiple
threads find a valid nonce simultaneously. Additionally, the code features a
global flag to indicate when a valid nonce has been found, allowing threads to
terminate early once a solution is discovered. This helps prevent unnecessary
computation and improves efficiency.
(Source: https://forums.developer.nvidia.com/t/how-to-stop-all-threads/4509/3)

***

# Results

The implementation was tested on the provided input data, and the results are as
follows:

00000466c22e6ee57f6ec5a8122e67f82a381499a4b3069869819639bb22a2ee,515800,0.10
00000466c22e6ee57f6ec5a8122e67f82a381499a4b3069869819639bb22a2ee,515800,0.06
00000466c22e6ee57f6ec5a8122e67f82a381499a4b3069869819639bb22a2ee,515800,0.05
00000466c22e6ee57f6ec5a8122e67f82a381499a4b3069869819639bb22a2ee,515800,0.05
00000466c22e6ee57f6ec5a8122e67f82a381499a4b3069869819639bb22a2ee,515800,0.07

The results show that the correct nonce was found for the given input data, with
the execution time ranging from 0.05 to 0.10 seconds. All the tests were
run on the xl cluster, and the results were consistent across multiple runs.

***

# Final Thoughts

Overall, the implementation successfully leverages CUDA to find the correct
nonce in a parallelized manner, reducing the time required to achieve
proof-of-work.

I really enjoyed working on this project and learning more about the Bitcoin
Proof of Work consensus algorithm. It was a great opportunity to apply the
knowledge gained in the laboratory to a real-world problem and explore the
potential of parallel programming on a GPU.