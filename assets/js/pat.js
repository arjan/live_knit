export const PatCanvas = {
  mounted() {
    const root = this.el;

    let canvas = null;
    let w = 0,
      h = 0;
    let draw = null;
    let fg = null,
      bg = null;

    function rebuildCanvas() {
      w = parseInt(root.getAttribute("data-w"), 10);
      h = parseInt(root.getAttribute("data-h"), 10);
      if (canvas != null) {
        root.removeChild(canvas);
      }

      canvas = document.createElement("canvas");
      canvas.setAttribute("width", w);
      canvas.setAttribute("height", h);
      draw = canvas.getContext("2d");
      draw.imageSmoothingEnabled = false;
      draw.webkitImageSmoothingEnabled = false;
      draw.mozImageSmoothingEnabled = false;

      bg = draw.createImageData(1, 1);
      bg.data[0] = 0;
      bg.data[1] = 0;
      bg.data[2] = 0;
      bg.data[3] = 255;

      fg = draw.createImageData(1, 1);
      fg.data[0] = 255;
      fg.data[1] = 255;
      fg.data[2] = 255;
      fg.data[3] = 255;

      root.appendChild(canvas);
    }
    function redrawCanvas() {
      const data = root.getAttribute("data-pat");
      for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
          const ch = data.charAt(y * w + x);
          draw.putImageData(ch == "0" || ch == " " ? bg : fg, x, y);
        }
      }
    }

    function callback(mutationList, observer) {
      const attrs = mutationList.map((m) => m.attributeName);
      if (attrs.includes("data-w") || attrs.includes("data-h")) {
        // full canvas rebuild
        rebuildCanvas();
      }
      // canvas redraw
      redrawCanvas();
    }

    const observerOptions = {
      childList: false,
      attributes: true,
      subtree: false,
    };

    const observer = new MutationObserver(callback);
    observer.observe(root, observerOptions);

    rebuildCanvas();
    redrawCanvas();
  },
};
