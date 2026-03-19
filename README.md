# Matrix Multiplication in hardware

## Overview
This repository contains the Verilog RTL design and verification environment for a hardware-accelerated matrix multiplication system, originally developed for the Digital Systems II coursework at the University of California, Davis. The core system is designed to compute the product of two $8\times8$ matrices using custom multiply-accumulate (MAC) architecture.

## System Architecture
* **MAC Unit:** Implements a custom Multiply Accumulator (MAC) that processes two 8-bit signed 2's complement inputs and maintains the running sum in a 19-bit signed accumulator register[cite: 37].
* **Parallel Processing:** Features a dual-ported memory architecture coupled with two independent MAC modules, allowing the system to fetch multiple operands and calculate two product entries in parallel.
* [cite_start]**Memory Management:** The $8\times8$ input matrices are stored in $64\times8$ RAM blocks formatted in column-major order. To handle simultaneous calculations, computed values are held in a 19-bit buffer register before being written sequentially to the single-ported $64\times19$ output RAM.
* [cite_start]**Control Logic:** Orchestrated by a custom Finite State Machine (FSM) that manages complex memory addressing schemes to fetch data efficiently without relying on standard software FOR-loops[cite: 55, 150, 181, 182]. 
* [cite_start]**Throughput Optimization:** Datapath pipelining and parallel MAC usage were implemented to maximize computational throughput (MAC/s). 

## Verification & Synthesis
* [cite_start]**Functional Verification:** Rigorously tested using custom testbenches, extracting and comparing internal RAM contents against expected matrix calculation results to ensure functional correctness[cite: 164, 165, 166].
* [cite_start]**Performance Tracking:** Integrated a custom clock cycle counter into the FSM to accurately profile execution time and identify architectural bottlenecks[cite: 65, 139].
* [cite_start]**Resource Utilization:** Analyzed synthesis results for hardware resource usage, including logic elements, flip-flops, and specialized M9K dual-ported memory blocks[cite: 103, 132].

## Technologies & Tools
* [cite_start]**Hardware Description Language:** Verilog [cite: 37]
* [cite_start]**Simulation:** ModelSim [cite: 72]
* [cite_start]**Target Architecture:** FPGA (utilizing embedded multipliers and M9K memory blocks) [cite: 45, 103, 132]

## Repository Structure
* `/src`: Contains all Verilog RTL source files (`.v`), including the MAC module, FSM controller, and top-level design.
* [cite_start]`/tb`: Contains testbenches and initialization files (`ram_a_init.txt`, `ram_b_init.txt`) used for memory loading via `$readmemb()`[cite: 68, 69].

## Visuals
> <img width="284" height="339" alt="Screenshot 2026-03-19 at 12 24 07 PM" src="https://github.com/user-attachments/assets/7f56c462-083a-47cb-9030-29757bf40894" />

<img width="292" height="307" alt="Screenshot 2026-03-19 at 12 23 43 PM" src="https://github.com/user-attachments/assets/d8705355-5389-4e29-87c2-3d0dc4423b39" />
