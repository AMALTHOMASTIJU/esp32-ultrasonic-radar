# ESP32 Ultrasonic Radar

A simple radar system built using ESP32, a servo motor and an ultrasonic sensor. 
The system scans the surroundings and visualizes detected objects using Processing.

## Hardware Used

- ESP32
- HC-SR04 Ultrasonic Sensor
- Servo Motor
- Jumper wires

## How it Works

1. The servo rotates the ultrasonic sensor.
2. Distance measurements are collected at different angles.
3. Data is sent through serial communication to Processing.
4. Processing displays a radar-style visualization.

## Problem Encountered

Ultrasonic sensors have a wide sound cone, which causes multiple readings for a single object.

## Solution

To reduce noise, clustering and averaging methods were applied to group nearby readings and produce more stable object detection.

## Tech Stack

- Arduino (ESP32)
- Processing
- Serial Communication

## Images

<img width="1480" height="836" alt="Screenshot 2026-03-08 212640" src="https://github.com/user-attachments/assets/d4b45c83-3147-4429-99fd-73e4a05ff419" />
<img width="3072" height="4080" alt="IMG_20260307_2130ss38398" src="https://github.com/user-attachments/assets/06892104-f64c-4975-8e2b-1ea105b7952a" />




## Future Improvements

- Better filtering methods
- Object tracking
- Higher resolution scanning
