# System Verilog APB2APB Bridge
---------------------------------------------------

GitHub repository: https://github.com/amiteee78/RTL_design/tree/master/apb2apb_bridge

## Introduction

Being a part of Advanced Microcontroller Bus Architecture (AMBA) family, the Advanced Peripheral Bus (APB) provides a low-cost interface optimized for minimal power consumption & reduced interface complexity. A well-defined interface between master & slave device is exploited to control both the read and write access of a SRAM (1KB). The architecture includes both flat testbech and RTL developed in System Verilog language Completely.

- Vivado Simulator tool provides free tool support for the beginners.

- Cadence Incisive Enterprise Simulator tool provides support for advanced learners.

[TOCM]

[TOC]

## Features

- **AMBA4** protocol supported.
- System Verilog Inteface implemeted.
- Memory access control with external **transfer** signal.
- Self-controlled binary data (**fullword**, **halfword** or **byte**) read & write access.
- Both single-mode & burst-mode memory access.
- configurable memory size according to the width of **address bus** (32 bit).

## Directoty Structure

    apb2apb_bridge/arch_specs  : Architecture specification directory.
    apb2apb_bridge/rtl         : Register Transfer Level source code directory.
    apb2apb_bridge/run_cad     : Cadence simulation directory.
    apb2apb_bridge/run_viv     : Vivado simulation directory.
    apb2apb_bridge/tb          : Flat Testbench directory.

## Source Files

    rtl/apb_bridge.sv          : APB Bridge Top.
    rtl/apbif.sv               : APB Interface.
    rtl/apb_master.sv          : APB Master.
    rtl/apb_mem.sv             : Single Port SRAM.
    rtl/apb_slave.sv           : APB Slave.

## Architecture Specification

This file provides all the specification needed to define the architecture.

`apb2apb_bridge/arch_specs/apb_arch.svh`

| Specification | Value  |
|:------------ |:------------ |
| APB address bus width | 32 bit  |
| APB data bus width  | 32 bit  |
| Memory size | 256 fullword  |
| Memory width | 8 bit  |
| Memory depth  | 4 byte |
| Strobe size  | 4 bit |
| Memory byte  | 1024 byte |

## Interface

## Common signals

    tdata   : Data (width generally DATA_WIDTH)
    tkeep   : Data word valid (width generally KEEP_WIDTH, present on _64 modules)
    tvalid  : Data valid
    tready  : Sink ready
    tlast   : End-of-frame
    tuser   : Bad frame (valid with tlast & tvalid)


## AXI Stream Interface Example

transfer with header data

                  __    __    __    __    __    __    __
    clk        __/  \__/  \__/  \__/  \__/  \__/  \__/  \__
               ______________                   ___________
    hdr_ready                \_________________/
                        _____ 
    hdr_valid  ________/     \_____________________________
                        _____
    hdr_data   XXXXXXXXX_HDR_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                        ___________ _____ _____
    tdata      XXXXXXXXX_A0________X_A1__X_A2__XXXXXXXXXXXX
                        ___________ _____ _____
    tdata      XXXXXXXXX_A0________X_A1__X_A2__XXXXXXXXXXXX
                        ___________ _____ _____
    tkeep      XXXXXXXXX_K0________X_K1__X_K2__XXXXXXXXXXXX
                        _______________________
    tvalid     ________/                       \___________
                              _________________
    tready     ______________/                 \___________
                                          _____
    tlast      __________________________/     \___________

    tuser      ____________________________________________


two byte transfer with sink pause after each byte

              __    __    __    __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _________________
    tdata  XXXXXXXXX_D0__X_D1______________XXXXXXXXXXXXXXXXXXXXXXXX
                    _____ _________________
    tkeep  XXXXXXXXX_K0__X_K1______________XXXXXXXXXXXXXXXXXXXXXXXX
                    _______________________
    tvalid ________/                       \_______________________
           ______________             _____             ___________
    tready               \___________/     \___________/
                          _________________
    tlast  ______________/                 \_______________________

    tuser  ________________________________________________________


two back-to-back packets, no pauses

              __    __    __    __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _____ _____ _____ _____ _____
    tdata  XXXXXXXXX_A0__X_A1__X_A2__X_B0__X_B1__X_B2__XXXXXXXXXXXX
                    _____ _____ _____ _____ _____ _____
    tkeep  XXXXXXXXX_K0__X_K1__X_K2__X_K0__X_K1__X_K2__XXXXXXXXXXXX
                    ___________________________________
    tvalid ________/                                   \___________
           ________________________________________________________
    tready
                                _____             _____
    tlast  ____________________/     \___________/     \___________

    tuser  ________________________________________________________


bad frame

              __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _____ _____
    tdata  XXXXXXXXX_A0__X_A1__X_A2__XXXXXXXXXXXX
                    _____ _____ _____
    tkeep  XXXXXXXXX_K0__X_K1__X_K2__XXXXXXXXXXXX
                    _________________
    tvalid ________/                 \___________
           ______________________________________
    tready
                                _____
    tlast  ____________________/     \___________
                                _____
    tuser  ____________________/     \___________


## Functional Verification

Running the included testbenches requires MyHDL and Icarus Verilog.  Make sure
that myhdl.vpi is installed properly for cosimulation to work correctly.  The
testbenches can be run with a Python test runner like nose or py.test, or the
individual test scripts can be run with python directly.

### Testbench Files

    tb/arp_ep.py         : MyHDL ARP frame endpoints

## Simulation

### Vivado Simulator


### Cadence Simulation