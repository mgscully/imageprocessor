module main
import os
import math
import math.complex
import gfx


const (
    // do not adjust these constants
    size       = Size2i{ 512, 512 }             // size of images to generate
    all_steps  = [8, 16, 256]                   // gradient step sizes to generate
    blends     = [0.00, 0.25, 0.50, 0.75, 1.00] // blend values to generate

    // change these constants
    over_extra = false                          // set to true for extra credit (varies alpha across image)
    //for my code, changing over_extra to true works for 'over' but not 'blend'
    iterations = 90000000                       // iterations for render algorithm, increase this before submitting!
)

// convenience type aliases
type Image   = gfx.Image
type Image4  = gfx.Image4
type Point2i = gfx.Point2i
type Size2i  = gfx.Size2i
type Color   = gfx.Color
type Color4  = gfx.Color4

type Compositor = fn(c_top Color4, c_bot Color4) Color4

// renders checkerboard image, alternating between even and odd colors
fn render_checkerboard(even Color, odd Color) Image {
    mut image := gfx.Image.new(size)

    for x in 0 .. image.width() {

        for y in 0 .. image.height() {

            if ((x+y) % 2) == 0{
                image.set_xy(x, y, even)
            }

            else {
                image.set_xy(x,y, odd)
            }
        }
    }

    return image
}

// // renders a stepped, vertical color gradient
fn render_gradient(top Color, bottom Color, num_steps int) Image {
    mut image := gfx.Image.new(size)


    //calculate band size 
    band_size := image.height()/num_steps

    //calculate step size for each color 
    r_step := f64(bottom.r-top.r)/f64(num_steps-1)
    g_step := f64(bottom.g-top.g)/f64(num_steps-1)
    b_step := f64(bottom.b-top.b)/f64(num_steps-1)

    

    //calculate current values for each color channel 
    mut curr_r := f64(top.r)
    mut curr_g := f64(top.g)
    mut curr_b := f64(top.b)
    
    
    for step in 0 .. num_steps {
        
        //calculate where this band should start and end 
        start_row := int(step * band_size)
        mut end_row := 0 
        if step == num_steps -1  {
            end_row = image.height()
        }
        else {
            end_row = start_row + band_size
        }

        //put into array to be compatible with color declaration 
        this_color := [curr_r, curr_g, curr_b]

        //create color 
        curr_color := gfx.color_from_f64(this_color)

        for y in start_row .. end_row {

            for x in 0 .. image.width() {

                image.set_xy(x,y,curr_color)

            }

        }
        //increment the color once the step is complete 
        curr_r += r_step
        curr_g += g_step
        curr_b += b_step 
    }

    return image
}

// color_over computes color of c_top over c_bottom
fn color_over(c_top Color4, c_bottom Color4) Color4 {
    mut c := Color4{ 0, 0, 0, 0 }

    //define individual values for rgb 
    mut r := 0.0 
    mut g := 0.0
    mut b := 0.0 
    mut alpha := 0.0

    //create variables for current color values and multiply them
    mut alpha_top := c_top.a
    mut r_top := c_top.r * alpha_top
    mut g_top := c_top.g * alpha_top
    mut b_top := c_top.b * alpha_top

    mut alpha_bottom := c_bottom.a 
    mut r_bottom := c_bottom.r * alpha_bottom
    mut g_bottom := c_bottom.g * alpha_bottom
    mut b_bottom := c_bottom.b * alpha_bottom
   
    //apply formula 
    r = (r_top + (1.0 - alpha_top) * r_bottom)
    g = (g_top + (1.0 - alpha_top) * g_bottom)
    b = (b_top + (1.0 - alpha_top) * b_bottom)
    alpha = (alpha_top + (1.0 - alpha_top) * alpha_bottom)

    //store color as non pre multiplied
    //watch out for dividing by 0 
    if alpha != 0 {
        r = r/alpha 
        g= g/alpha 
        b= b/alpha
    }
    else {
        r= 0.0
        g= 0.0 
        b =0.0
    }
    

    c = Color4{r, g, b, alpha}


    return c
}

// color_blend computes color of blending c0 into c1 by factor.
// - when factor == 0.0, final color is c0
// - when factor == 0.5, final color is average of c0 and c1
// - when factor == 1.0, final color is c1
fn color_blend(c0 Color4, c1 Color4, factor f64) Color4 {

    mut c := Color4{ 0, 0, 0, 0 }

    //colors are not premultiplied 
    mut alpha_f := (1.0 - factor)*c0.a + (factor * c1.a)

    if alpha_f > 1.0 {
        alpha_f = 1.0
    }

    mut r_f := 0.0
    mut g_f := 0.0
    mut b_f := 0.0

    if alpha_f != 0 {
        r_f = ((1.0 - factor) * c0.r * c0.a + (factor * c1.r * c1.a)) / alpha_f
        g_f = ((1.0 - factor) * c0.g * c0.a + (factor * c1.g * c1.a)) / alpha_f
        b_f = ((1.0 - factor) * c0.b * c0.a + (factor * c1.b * c1.a)) / alpha_f
    }
 
    c = Color4{r_f, g_f, b_f, alpha_f}

    return c
}


// render_composite will create an image based on passing corresponding pixels from img_top and img_bot into fn_composite
// these functions might be oriented slightly differently than they were originally because i tried to modify them to accept images of different sizes, but ran out of time so changed them back
fn render_composite(img_top Image4, img_bot Image4, fn_composite Compositor) Image4 {
    
    assert img_top.size.width == img_bot.size.width && img_top.size.height == img_bot.size.height 
    mut image := gfx.Image4.new(img_top.size)
    for y in 0 .. img_top.size.height {
        for x in 0 .. img_top.size.width {
            c_top := img_top.get_xy(x, y)
            c_bot := img_bot.get_xy(x, y)
            c_comp := fn_composite(c_top, c_bot)
            image.set_xy(x, y, c_comp)
        }
    }
    return image  

}


// convenience struct that groups a Point2i with Color
struct PointColor {
    position Point2i
    color    Color
}

// render_algorithm renders an image following a simple algorithm
fn render_algorithm0() Image {
    mut image := gfx.Image.new(size)

    // pick three random locations and colors
    min := Point2i{0, 0}
    max := Point2i{size.width, size.height}
    corners := [
        PointColor{ gfx.point2i_rand(min, max), gfx.red },
        PointColor{ gfx.point2i_rand(min, max), gfx.green },
        PointColor{ gfx.point2i_rand(min, max), gfx.blue },
    ]
    mut position := gfx.point2i_rand(min, max)
    mut color    := Color{ 0,0,0 }

    for iteration in 0 .. iterations {

        //write color into image at position
        image.set(position, color)

        //choose one of the corners at random 
        index := gfx.int_in_range(0,3)

        mut corner := corners[index]

        //set position to halfway to corner position

        pos_x := (corner.position.x + position.x)/2
        pos_y := (corner.position.y + position.y)/2

        position = Point2i {pos_x, pos_y}

        //update color to halfway to corner color 
        color.r = ((color.r+corner.color.r)/2.0)
        color.g = ((color.g + corner.color.g)/2.0)
        color.b = ((color.b + corner.color.b)/2.0)

    }

    return image
}

fn render_algorithm1() Image {
    mut image := gfx.Image.new(size)
    w, h := image.width(), image.height()
    max_iterations := gfx.ramp.len() * 10

    for x in 0 .. w {

        for y in 0 .. h {

            //initialize z to the complex number (  0  ) + (  0  )i 
            mut z := complex.Complex{0.0 , 0.0}

            //initialize c to the complex number  (2 * x / w - 1.5) + (2 * y / h - 1.0)i
            c := complex.Complex{ 2.0 * f64(x)/f64(w) - 1.5 , 2.0 * f64(y)/f64(h) - 1.0}

            //iterate maximum of max_iterations times
            for i in 0 .. max_iterations {
                
                //update z to z = z*z + c
                z = (z * z) + c

                //verify that z is not trending toward infinity
                if z.abs() > 2 {
                    image.set_xy(x, y, gfx.ramp.color(i))
                    break
                }


            }

        }
    }

    return image
}

//other color compositing functions 

//extra compositing function, multiply
fn multiply (c_top Color4, c_bottom Color4) Color4 {

    mut c := Color4{ 0, 0, 0, 0 }

    //define individual values for rgb 
    mut r := 0.0 
    mut g := 0.0
    mut b := 0.0 
    mut alpha := 0.0

    r = c_top.r * c_bottom.r 
    g = c_top.g * c_bottom.g 
    b = c_top.b * c_bottom.b 
    alpha = c_top.a * c_bottom.a 

    c = Color4{r,g,b,alpha}

    return c 

}

//extra compositing function: divide
fn divide (c_top Color4, c_bottom Color4) Color4 {

    mut c := Color4{ 0, 0, 0, 0 }

    //define individual values for rgb 
    mut r := 0.0 
    mut g := 0.0
    mut b := 0.0 
    mut alpha := 0.0

    r = c_top.r / c_bottom.r 
    g = c_top.g / c_bottom.g 
    b = c_top.b / c_bottom.b 
    alpha = c_top.a / c_bottom.a 

    if alpha > 1.0 {
        alpha = 1.0
    }

    c = Color4{r,g,b,alpha}

    return c 

}

//extra compositing function 
//accepts a single image and brightens it by a fixed factor across all color channels
fn brightness (factor f64, img Image4) Image4 {
    
    //create a new image
    mut image := gfx.Image4.new(size)

    //iterate through every pixel 
    for x in 0 .. image.width() {

        for y in 0 .. image.height() {
            //adjust by factor 
            mut r := (img.get_xy(x,y)).r + factor 
            mut g := (img.get_xy(x,y)).g + factor 
            mut b := (img.get_xy(x,y)).b + factor 

            //verify no value becomes over one
            if r > 1.0 {
                r = 1.0
            }
            if g > 1.0 {
                g = 1.0 
            }
            if b > 1.0 {
                b = 1.0 
            }
            //alpha does not change
            alpha := (img.get_xy(x,y)).a 

            mut c := Color4 {r,g,b,alpha}

            image.set_xy(x,y,c)
        }
    }

    return image

}

//extra compositing function
fn additive (c0 Color4, c1 Color4) Color4{

    //create new color 
    mut c := Color4{ 0, 0, 0, 0 }

    mut alpha := (c0.a + c1.a)

    if alpha > 1.0 {
        alpha = 1.0
    }
    
    mut r := 0.0 
    mut g := 0.0 
    mut b := 0.0

    if alpha != 0.0 {
        r = ((c0.r * c0.a) + (c1.r * c1.a)) / alpha 
        g = ((c0.g * c0.a) + (c1.g * c1.a)) / alpha
        b = ((c0.b * c0.a) + (c1.b * c1.a)) / alpha
    }

    c = Color4{r, g, b, alpha}

    return c 

}

//extra compositing function (subtractive)
fn subtractive (c0 Color4, c1 Color4) Color4{

    //create new color 
    mut c := Color4{ 0, 0, 0, 0 }

    mut alpha := (c0.a - c1.a)

    if alpha < 0.0 {
        alpha = 0.0
    }
    
    mut r := 0.0 
    mut g := 0.0 
    mut b := 0.0

    if alpha > 0.0 {
        r = ((c0.r * c0.a) - (c1.r * c1.a)) / alpha
        g = ((c0.g * c0.a) - (c1.g * c1.a)) / alpha
        b = ((c0.b * c0.a) - (c1.b * c1.a)) / alpha

        if (r < 0.0) {
            r = 0.0
        }
        if (g < 0.0) {
            g = 0.0
        }
        if (b < 0.0) {
            b = 0.0
        }
    }

    c = Color4{r, g, b, alpha}

    return c 

}

//extra compositing function: saturation
//method: tones the image to only the color determined by the code
fn tone (img Image4, code string) Image4 {
    
    //create a new image
    mut image := gfx.Image4.new(size)

    //iterate through every pixel 
    for x in 0 .. image.width() {

        for y in 0 .. image.height() {

            //initally set all color channels to 0

            //determine values of color channels for the pixel
            mut r := 0.0
            mut g := 0.0
            mut b := 0.0

            if code == 'r' {
               r = (img.get_xy(x,y)).r
            }

            if code == 'g' {
                g = (img.get_xy(x,y)).g
            }

            if code == 'b' {
                b = (img.get_xy(x,y)).b

            } 

           
            alpha := (img.get_xy(x,y)).a 

            mut c := Color4 {r,g,b,alpha}

            image.set_xy(x,y,c)
        }
    }

    return image

    
}

//my creative artifact 
//goal of function is to pick a few random regions of a picture and move them somewhere
//else like body parts in a picasso painting
fn picasso (filename string) Image4{

    mut image := gfx.load_png(filename)

    w := image.width() 
    h := image.height()

    //define a size for the regions to move around proportional to size 
    //played around with this to find out what looked coolest 
    //regions are rectangular 
    region_w := w / 4
    region_h := h / 4

    //define number of regions to move around 
    number_regions := 6

    for region in 0 .. number_regions {

        // Ensure regions are fully within the image boundaries
        x1 := gfx.int_in_range(0, w - region_w)
        y1 := gfx.int_in_range(0, h - region_h)
        x2 := gfx.int_in_range(0, w - region_w)
        y2 := gfx.int_in_range(0, h - region_h)

        
        for i in 0 .. region_w {

            for j in 0 .. region_h {

                mut curr_x1 := x1 + i
                mut curr_x2 := x2 + i
                mut curr_y1 := y1 + j 
                mut curr_y2 := y2 + j 
    
                //if all pixels are in range, swap colors 
                c1 := image.get_xy(curr_x1, curr_y1)
                c2 := image.get_xy(curr_x2, curr_y2)
                image.set_xy(curr_x1, curr_y1, c2)
                image.set_xy(curr_x2, curr_y2, c1)
                    

                }
        
        }

    }
    return image
}


fn main() {
    // Make sure images folder exists, because this is where all
    // generated images will be saved
    if !os.exists('output') {
        os.mkdir('output') or { panic(err) }
    }

    println('Rendering images A and B...')
    img_a := gfx.render_image0(size)
    img_b := gfx.render_image1(size, over_extra)  // set to true for extra credit (varies alpha across image)

    println('Writing images A and B...')  // write images out just to see them
    img_a.save_png('output/P00_image_A.png')
    img_b.save_png('output/P00_image_B.png')

    println('Testing image loading...')
    test := gfx.load_png('output/P00_image_A.png')
    test.save_png('output/P00_image_A_test.png')

    println('Rendering checkerboard image...')
    render_checkerboard(gfx.red, gfx.cyan).save_png('output/P00_checkerboard.png')

    println('Rendering gradient images...')
    for num_steps in all_steps {
        render_gradient(Color{0,0,0}, Color{1,1,1}, num_steps).save_png('output/P00_00_gradient_${num_steps:03}.png')
    }

    println('Rendering composite color_over images...')
    render_composite(img_a, img_b, color_over).save_png('output/P00_01_A_over_B.png')
    render_composite(img_b, img_a, color_over).save_png('output/P00_01_B_over_A.png')

    println('Rendering composite color_blend images...')
    for blend in blends {
        render_composite( img_a, img_b, fn [blend] (c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, blend)
        }).save_png('output/P00_02_A_blend${int(100*blend):03}_B.png')
    }

    println('Rendering algorithm 0 image...')
    render_algorithm0().save_png('output/P00_03_algorithm0.png')

    println('Rendering algorithm 1 image...')
    render_algorithm1().save_png('output/P00_04_algorithm1.png')

    println ('Rendering multiply image')
    render_composite(img_a, img_b, multiply).save_png('output/P00_01_A_times_B.png')

    println ('Rendering divide image')
    render_composite(img_a, img_b, divide).save_png('output/P00_01_A_divided_B.png')

    gfx.render_image1(size, over_extra).save_png('output/P00_01_A_divided_B.png')

    println('Rending brightened image')
    brightness(0.25, img_a).save_png('output/P00_01_A_brightened.png')

    println ('Rendering additive image')
    render_composite(img_a, img_b, additive).save_png('output/P00_01_A_additive_B.png')
    
    println ('Rendering subtractive image')
    render_composite(img_b, img_a, subtractive).save_png('output/P00_01_A_subtractive_B.png')

    println('Rending saturated image')
    tone(img_b, 'g').save_png('output/P00_01_A_tone.png')

    println('Rendering picassoed image 1(image a)')
    picasso('output/P00_image_A.png').save_png('output/P00_creative_element1.png')
    //this may have to be changed when run on a different device
    println('Rendering picassoed image 2 (homer simpson))')
    picasso('P00_Image/references/homer_simpson.png').save_png('output/P00_creative_element.png')
    println('Done!')

}