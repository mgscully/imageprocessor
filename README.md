# Image Processing Project
## Overview
This project involves generating and manipulating images using various rendering and compositing techniques. The primary objective is to experiment with different algorithms for creating visual effects and to apply creative transformations to images. This README provides an overview of the project's functionalities, how to use it, and the purpose of each component.

## Project Structure
- main module: Contains the main logic for image generation, rendering, and saving.
- gfx module: A custom graphics module used for image manipulation and rendering. **provided for me by my professor 
- functions module: Contains various functions for image processing and compositing.
  
## Generating Images:

The main module contains the main function, which orchestrates the rendering and saving of images.
Execute the main function to generate and save various images into the output directory.

## Generated Images:

- P00_image_A.png: Image generated using render_image0().
- P00_image_B.png: Image generated using render_image1().
- P00_checkerboard.png: Checkerboard pattern with red and cyan colors.
- P00_00_gradient_<steps>.png: Gradient images with varying step sizes.
- P00_01_A_over_B.png, P00_01_B_over_A.png: Composite images using the color_over function.
- P00_02_A_blend<blend>_B.png: Composite images using the color_blend function with different blend factors.
- P00_03_algorithm0.png: Image generated using render_algorithm0().
- P00_04_algorithm1.png: Image generated using render_algorithm1().
- P00_01_A_times_B.png, P00_01_A_divided_B.png: Composite images using the multiply and divide functions.
- P00_01_A_brightened.png: Brightened version of image A.
- P00_01_A_additive_B.png, P00_01_A_subtractive_B.png: Composite images using the additive and subtractive functions.
- P00_01_A_tone.png: Image with colors toned to green.
- P00_creative_element1.png, P00_creative_element.png: Picasso-style transformed images.
  
## Running the Project:

Ensure the output directory exists or is created before running the project.
Execute the main function to generate the images. The function handles rendering, saving, and applying various effects.
Functions

## Rendering Functions:

- render_checkerboard(even Color, odd Color) Image: Renders a checkerboard pattern.
- render_gradient(top Color, bottom Color, num_steps int) Image: Renders a vertical color gradient.
- render_algorithm0() Image: Renders an image using an iterative algorithm.
- render_algorithm1() Image: Renders an image using a fractal algorithm.
  
## Compositing Functions:

- color_over(c_top Color4, c_bottom Color4) Color4: Computes color of c_top over c_bottom.
- color_blend(c0 Color4, c1 Color4, factor f64) Color4: Blends two colors by a factor.
- multiply(c_top Color4, c_bottom Color4) Color4: Multiplies two colors.
- divide(c_top Color4, c_bottom Color4) Color4: Divides one color by another.
- additive(c0 Color4, c1 Color4) Color4: Adds two colors.
- subtractive(c0 Color4, c1 Color4) Color4: Subtracts one color from another.
- tone(img Image4, code string) Image4: Tones an image to a specific color.
- brightness(factor f64, img Image4) Image4: Adjusts brightness of an image.
- picasso(filename string) Image4: Applies a Picasso-style transformation to an image.
