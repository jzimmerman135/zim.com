"use strict";

function webGLFromShadertoy(raw_code) {
    return `#version 300 es
precision highp float;

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
// uniform float iClick;
`
   + raw_code + 
`
out vec4 outColor;
void main() {
    mainImage(outColor, gl_FragCoord.xy);
}`;
}

function fetchFragShader(canvas, filepath) {
    fetch(filepath)
    .then(response => response.text())
    .then((shaderSource) => {
        startFragShader(canvas, shaderSource)
    });
}

function fetchShadertoyShader(canvas, filepath) {
    fetch(filepath)
    .then(response => response.text())
    .then((shaderSource) => {
        startFragShader(canvas, webGLFromShadertoy(shaderSource));
    });
}

function startFragShader(canvas, fs) {    
    const gl = canvas.getContext("webgl2");
    if (!gl) {
      return;
    }
  
    const vs = `#version 300 es
      // an attribute is an input (in) to a vertex shader.
      // It will receive data from a buffer
      in vec4 a_position;
  
      // all shaders have a main function
      void main() {
  
        // gl_Position is a special variable a vertex shader
        // is responsible for setting
        gl_Position = a_position;
      }
    `;

    // setup GLSL program
    const program = webglUtils.createProgramFromSources(gl, [vs, fs]);
  
    // look up where the vertex data needs to go.
    // look up uniform locations
    const positionAttributeLocation = gl.getAttribLocation(program, "a_position");
    const resolutionLocation = gl.getUniformLocation(program, "iResolution");
    const mouseLocation = gl.getUniformLocation(program, "iMouse");
    const timeLocation = gl.getUniformLocation(program, "iTime");
    // const clickLocation = gl.getUniformLocation(program, "iClick");

    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    const positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
      -1, -1,  // first triangle
       1, -1,
      -1,  1,
      -1,  1,  // second triangle
       1, -1,
       1,  1,
    ]), gl.STATIC_DRAW);
  
    // Turn on the attribute
    // Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
    gl.enableVertexAttribArray(positionAttributeLocation);
    gl.vertexAttribPointer(
        positionAttributeLocation,
        2,          // 2 components per iteration
        gl.FLOAT,   // the data is 32bit floats
        false,      // don't normalize the data
        0,          // 0 = move forward size * sizeof(type) each iteration to get the next position
        0,          // start at the beginning of the buffer
    );
  
    const inputElem = document.getElementById('blockapurple');
    inputElem.addEventListener('mouseover', requestFrame);
    inputElem.addEventListener('mouseout', cancelFrame);
  
    let mouseX = 0;
    let mouseY = 0;
    // let isClick = 0;
  
    function setMousePosition(e) {
      const rect = inputElem.getBoundingClientRect();
      mouseX = e.clientX - rect.left;
      mouseY = rect.height - (e.clientY - rect.top) - 1;  // bottom is 0 in WebGL
    }
  
    inputElem.addEventListener('mousemove', setMousePosition);
    inputElem.addEventListener('touchstart', (e) => {
      e.preventDefault();
      requestFrame();
    }, {passive: false});
    inputElem.addEventListener('touchmove', (e) => {
      e.preventDefault();
      setMousePosition(e.touches[0]);
    }, {passive: false});
    inputElem.addEventListener('touchend', (e) => {
      e.preventDefault();
      cancelFrame();
    }, {passive: false});
  
    let requestId;

    function requestFrame() {
      if (!requestId) {
        requestId = requestAnimationFrame(render);
      }
    }

    function cancelFrame() {
      if (requestId) {
        cancelAnimationFrame(requestId);
        requestId = undefined;
      }
    }
  
    let then = 0;
    let time = 0;
    function render(now) {
      requestId = undefined;
      now *= 0.001;  // convert to seconds
      const elapsedTime = Math.min(now - then, 0.1);
      time += elapsedTime;
      then = now;
    
      webglUtils.resizeCanvasToDisplaySize(gl.canvas);
      // Tell WebGL how to convert from clip space to pixels
      // Tell it to use our program (pair of shaders)
      // Bind the attribute/buffer set we want.
      gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
      gl.useProgram(program);
      gl.bindVertexArray(vao);
      gl.uniform2f(resolutionLocation, gl.canvas.width, gl.canvas.height);
      gl.uniform2f(mouseLocation, mouseX, mouseY);
      gl.uniform1f(timeLocation, time);
    //   gl.uniform1i(clickLocation, isClick);
      gl.drawArrays(
          gl.TRIANGLES,
          0,     // offset
          6,     // num vertices to process
      );
  
      requestFrame();
    }
  
    requestFrame();
    requestAnimationFrame(cancelFrame);
}