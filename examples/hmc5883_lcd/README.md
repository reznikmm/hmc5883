# HMC5883L LCD demo

This folder contains a demonstration program showcasing the functionality
of a magnetometer sensor using the STM32 F4VE board
and an LCD display included in the kit. The program features a straightforward
graphical user interface (GUI) for configuring sensor parameters.

![Demo screenshot](hmc5883_lcd_x2.png)

## Overview

The demonstration program is designed to work with the STM32 F4VE development
board and a compatible LCD display. It provides a GUI interface to configure
sensor parameters such as average count, gain and self-test bias.
The display includes buttons for enabling/disabling the display of
measurement (Fx, Fy, Fz). Additionally, there are buttons (`G0` .. `G7`) for
controlling the gain. Yellow buttons (`A1`, `A2`, `A4`, `A8`) control the
average count. Additionally, dim grey buttons labeled `B-`, `B+` enable
self-test bias, while `B0` button disables it.

## Requirements

* STM32 F4VE development board
* Any HMC5883L module
* Compatible LCD display/touch panel included in the kit
* Development environment compatible with STM32F4 microcontrollers

## Setup

* Attach HMC5883L by I2C to PB9 (SDA), PB8 (SCL)
* Attach the LCD display to the designated port on the STM32F4VE board.
* Connect the STM32 F4VE board to your development environment.

## Usage

Compile and upload the program to the STM32 F4VE board. Upon successful upload,
the demonstration program will run, displaying sensor data on the LCD screen.
Activate the buttons on the GUI interface using the touch panel.
Simply touch the corresponding button on the LCD screen to toggle its state.
