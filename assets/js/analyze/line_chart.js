// assets/js/line_chart.js

const COLORS = ["#aaff00", "#ff9900"];
const DX = 0.00002;
const DY = 30;
let scale = 10;

// A wrapper of Chart.js that configures the realtime line chart.
export default class {
  constructor(canvas) {
    const r = canvas.getBoundingClientRect();

    this.canvas = canvas;
    this.canvas.setAttribute("width", r.width);
    this.canvas.setAttribute("height", r.height);

    this.ctx = this.canvas.getContext("2d");
    this.width = r.width;
    this.height = r.height;

    document.body.addEventListener("keyup", (e) => {
      switch (e.key) {
        case "r":
          this.reset();
          break;
        case "]":
          scale++;
          this.reset();
          break;
        case "[":
          scale--;
          this.reset();
          break;
      }
    });

    this.reset();
  }

  reset() {
    const c = this.ctx;
    c.beginPath();
    c.rect(0, 0, this.width, this.height);
    c.fillStyle = "black";
    c.fill();
    this.prevValues = null;
    console.log("Scale:", scale);
  }

  addPoint(time, values) {
    const c = this.ctx;
    c.lineWidth = 1;

    const [ox] = this.translate(0, time, 0);
    c.beginPath();
    c.strokeStyle = "#333";
    c.moveTo(ox, 0);
    c.lineTo(ox, this.height);
    c.stroke();

    if (this.prevValues) {
      let x, y;
      for (let i = 0; i < values.length; i++) {
        c.beginPath();
        c.strokeStyle = COLORS[i];

        [x, y] = this.translate(i, this.prevTime, this.prevValues[i]);
        c.moveTo(x, y);
        [x, y] = this.translate(i, time, this.prevValues[i]);
        c.lineTo(x, y);
        if (this.prevValues[i] !== values[i]) {
          [x, y] = this.translate(i, time, values[i]);
          c.lineTo(x, y);
        }
        c.stroke();
      }
    } else {
      this.startTime = time;
    }

    this.prevTime = time;
    this.prevValues = values;

    const [x] = this.translate(0, time);

    if (x >= this.width) {
      this.reset();
    }
  }

  translate(i, time, y) {
    const x = (time - this.startTime) * DX * scale;
    return [x, DY + i * 3 * DY + (y ? 0 : 1) * DY];
  }

  destroy() {}
}
