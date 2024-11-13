import Module from "./nx_iree_runtime.mjs";

export const WasmWebcamHookMount = async (hook) => {
  const fps = 30;
  const interval = 1000 / fps;

  const instance = await Module();
  let device = instance.createDevice();
  const video = document.getElementById("wasm-webcam");

  hook.runtime = { instance, device };

  let type = "u8";

  const canvas = document.getElementById("wasm-webcam-input");
  const context = canvas.getContext("2d", { willReadFrequently: true });
  const outputCanvas = document.getElementById("wasm-webcam-output");
  const outputContext = outputCanvas.getContext("2d");
  canvas.width = 0 + video.getAttribute("width");
  canvas.height = 0 + video.getAttribute("height");

  // Create an ImageData object
  let imageData = outputContext.createImageData(canvas.width, canvas.height);

  hook.processing = false;
  hook.lastFrameTime = 0;
  hook.targetFrameInterval = 1000 / 15; // 15 FPS

  hook.durations = {
    input: null,
    call: null,
    output: null,
    bytecode: null,
  };

  function processFrame(video) {
    const bytecode_data_attr = video.getAttribute("data-bytecode");
    const filter_kind = video.getAttribute("data-filter-kind");

    if (video.videoWidth === 0 || video.videoHeight === 0) {
      return;
    }

    // Performance debugging
    const frameStart = performance.now();

    context.drawImage(video, 0, 0, canvas.width, canvas.height);

    if (bytecode_data_attr === "") {
      let inputData = context.getImageData(0, 0, canvas.width, canvas.height);
      imageData.data.set(inputData.data);
      outputContext.putImageData(imageData, 0, 0);
      inputData = null;
      return;
    }

    const inputStart = performance.now();
    // Get the ImageData object from the canvas (whole canvas)
    let inputData = context.getImageData(0, 0, canvas.width, canvas.height);
    let uint8ClampedArray = inputData.data;
    let inputArray = new Uint8Array(uint8ClampedArray);

    // Clean up inputData after copying
    inputData = null;
    uint8ClampedArray = null;

    let shape = new Int32Array([canvas.height, canvas.width, 4]);

    let input = undefined;
    try {
      input = new instance.Tensor.create(
        inputArray,
        shape,
        type,
        hook.runtime.device
      );
      inputArray = null;
      shape = null;
    } catch (error) {
      console.error(error);
      return;
    }

    let inputs = new instance.vector_Tensor();
    inputs.push_back(input);

    if (filter_kind === "tint") {
      const tint_params = document
        .getElementById("tint-params")
        .getAttribute("content");
      const tint_inputs = JSON.parse(tint_params);

      let inputs_f32 = new Float32Array(tint_inputs);
      let tint_shape = new Int32Array([4]);
      const tint_input_tensor = new instance.Tensor.create(
        inputs_f32,
        tint_shape,
        "f32",
        hook.runtime.device
      );
      inputs_f32 = null;
      tint_shape = null;

      inputs.push_back(tint_input_tensor);
    }

    const inputDuration = performance.now() - inputStart;
    hook.durations.input = hook.durations.input
      ? (inputDuration + hook.durations.input) / 2
      : inputDuration;

    // let bytecode = hook.runtime.bytecode;

    const bytecodeStart = performance.now();
    // if (!hook.runtime.bytecode) {

    const bytecode_data = atob(bytecode_data_attr);

    // Create a Uint8Array from the decoded base64 string
    let bytecode_uint8Array = new Uint8Array(bytecode_data.length);

    for (let i = 0; i < bytecode_data.length; i++) {
      bytecode_uint8Array[i] = bytecode_data.charCodeAt(i);
    }

    const bytecode = new instance.DataBuffer.create(bytecode_uint8Array);
    bytecode_uint8Array = null;
    const bytecodeDuration = performance.now() - bytecodeStart;
    hook.durations.bytecode = hook.durations.bytecode
      ? (bytecodeDuration + hook.durations.bytecode) / 2
      : bytecodeDuration;

    const callStart = performance.now();

    let vminstance = instance.createVMInstance();

    let [call_status, outputs] = instance.call(
      vminstance,
      device,
      bytecode,
      inputs
    );

    const callDuration = performance.now() - callStart;
    hook.durations.call = hook.durations.call
      ? (callDuration + hook.durations.call) / 2
      : callDuration;

    bytecode.delete();

    if (!instance.statusIsOK(call_status)) {
      console.error("Error calling the VM instance");
      console.error(instance.getStatusMessage(call_status));

      call_status.delete();
      for (let i = 0; i < inputs.size(); i++) {
        inputs.get(i).delete();
      }
      inputs.delete();
      return;
    }

    call_status.delete();
    const outputStart = performance.now();
    const outputTensor = outputs.get(0);
    let outputArray = outputTensor.toFlatArray();
    for (let i = 0; i < outputs.size(); i++) {
      outputs.get(i).delete();
    }
    outputs.delete();

    imageData.data.set(outputArray);
    outputArray = null;

    const outputDuration = performance.now() - outputStart;
    hook.durations.output = hook.durations.output
      ? (outputDuration + hook.durations.output) / 2
      : outputDuration;

    // Draw the ImageData onto the canvas
    outputContext.putImageData(imageData, 0, 0);

    for (let i = 0; i < inputs.size(); i++) {
      inputs.get(i).delete();
    }
    inputs.delete();

    // Log total frame time if it's high
    const totalTime = performance.now() - frameStart;
    if (totalTime > 50) {
      // Log if frame takes more than 50ms
      console.debug(`Long frame: ${totalTime.toFixed(1)}ms`);
      // Optionally log individual timings
      console.debug({
        input: hook.durations.input,
        bytecode: hook.durations.bytecode,
        call: hook.durations.call,
        output: hook.durations.output,
      });
    }
  }

  function animationLoop(timestamp) {
    // Skip if we're still processing the last frame
    if (hook.processing) {
      requestAnimationFrame(animationLoop);
      return;
    }

    // Check if enough time has passed since last frame
    if (timestamp - hook.lastFrameTime < hook.targetFrameInterval) {
      requestAnimationFrame(animationLoop);
      return;
    }

    hook.processing = true;
    hook.lastFrameTime = timestamp;

    try {
      processFrame(video);
    } catch (error) {
      console.error("Frame processing error:", error);
    } finally {
      hook.processing = false;
      requestAnimationFrame(animationLoop);
    }
  }

  if (navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices
      .getUserMedia({ video: true })
      .then(function (stream) {
        video.srcObject = stream;
        // Start the animation loop
        requestAnimationFrame(animationLoop);
      })
      .catch(function (error) {
        console.log("Something went wrong!");
      });
  }
};

export const WasmWebcamHookDestroy = (hook) => {
  // hook.runtime.bytecode.delete();
  hook.runtime.device.delete();
  // hook.runtime.vminstance.delete();
};
