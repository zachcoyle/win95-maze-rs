# Win 95 Screensaver Maze in Rust

Win 95® screensaver maze in Rust with OpenGL.

Some code take from bwasty's [learn-opengl-rs](https://github.com/bwasty/learn-opengl-rs/).

## Compiling/Installing

Should be as easy as:

```rust
cargo install
```

And then

```rust
win95-maze
```

or

```rust
win95-maze --fullscreen
```

for the full experience.

## Design

### Maze

After initializing the window and GL contexts, we create a `Maze` struct:

```rust
pub struct Maze {
    pub grid: Vec<Vec<u8>>,
    pub width: usize,
    pub height: usize
}
```

This is basically a matrix of 4 bit bit-fields, denoting for each maze cell
if it has a wall to the North, East, South or West.

The grid is initially filled with zeroes, and then populated using a
[recursive backtracker](https://en.wikipedia.org/wiki/Maze_generation_algorithm#Recursive_backtracker).
The code for this is heavily based on [Jamis Buck's ruby implementation](http://weblog.jamisbuck.org/2010/12/27/maze-generation-recursive-backtracking).

### Camera

The camera is as simple as:

```rust
pub struct Camera {
    pub pos: Point3<f32>,
    pub dir: Vector3<f32>,
    pub up: Vector3<f32>,
    pub upside_down: bool,
}
```

where `upside_down` is used to decide where to roll (if world-up or world-down),
and `up` used to turn (it's kinda useless here since we always rotate around
world-y but it's more correct, also we need it to roll).

The camera has three methods to move around: `move_to`, `rotate_to` and `roll_to`.
Each one takes a point or vector and modifies the camera to approach it,
returning `true` when it's done. This is done each frame.

When they return `true`, it means we need to calculate the next state.

### Walker

To know where to move the camera when navigating the maze, we have a `Walker`:

```rust
pub struct Walker<'a> {
    maze: &'a Maze,
    pub direction: Direction,
    pub i: usize,
    pub j: usize
}
```

This holds a reference to the maze and a position inside it in grid coordinates,
and a `direction` used to know where the camera needs to look to.

The walker has a `next` method, which calculates the next position and direction.
It will always move forward and choose randomly in a bifurcation.

### Rendering

Walls and icosahedrons are similar structs, with a `pos: Vector<f32>` position
vector and other specific data. Each has an associated renderer struct which holds the
VAO (vertex array object) and does the OpenGL initializing mambo-jambo.

Both renderers have a `draw` method which takes the shader program,
sets the appropriate matrices in the shader's uniforms and does the rendering.

The wall renderer has an extra check for when the texture type changed
between drawings, so it only has to set those uniforms when needed.

### Shaders

The `Shader` and `Texture` modules are basically taken from [learn-opengl-rs](https://github.com/bwasty/learn-opengl-rs/). They mainly initialize some OpenGL stuff.

The shaders themselves are pretty simple: the vertex shader multiplies the
model, view and projection matrices and then just passes the
texture and normal properties down the pipeline to the fragment shader.

Here, we find a little abuse of OpenGL's flexibility:

```glsl
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTex;
layout (location = 2) in vec3 aNor;
```

The `aTex` property is used by the walls (to map the texture), and the `aNor` by
the icos (to calculate the diffuse lighting).
But their respective vertex data doesn't define both, only the one they use.
So, the VAO of each object then goes on to activate only the relevant attribute.

So the `IcoRenderer` enables the third attribute (counting from 0):

```rust
// aNor = 2
gl::VertexAttribPointer(2, 3, gl::FLOAT, gl::FALSE,
                        6 * mem::size_of::<GLfloat>() as GLint,
                        (3 * mem::size_of::<GLfloat>()) as *const GLvoid);
gl::EnableVertexAttribArray(2);
```

but not the second, and vice versa for the `WallRenderer`. I'm not sure if this
was smart or just plain awful though.

Finally the fragment shader, decides based on a `solid` flag, if to render using
a texture or a diffuse lighting color.

### State

There is also a simple state machine

```rust
enum State {
    Walking,
    Turning,
    Rolling
}
```

to control the camera, which after the completion of the
movement methods, decides which state to take next with the position of
the icosahedrons and the walker's direction.

## Screenshots

![hallway](https://raw.githubusercontent.com/alvare/win95-maze-rs/master/screenshots/4.png)

![icosahedron](https://raw.githubusercontent.com/alvare/win95-maze-rs/master/screenshots/5.png)
