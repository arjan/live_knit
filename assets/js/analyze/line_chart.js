// assets/js/line_chart.js

const COLORS = ["#aaff00", "#ff9900"];
const DX = 10;
const DY = 30;

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

    this.reset();
  }

  reset() {
    const c = this.ctx;
    c.beginPath();
    c.rect(0, 0, this.width, this.height);
    c.fillStyle = "black";
    c.fill();
    this.x = 0;
  }

  addPoint(values) {
    const c = this.ctx;
    c.lineWidth = 1;

    if (this.prevValues) {
      let x, y;
      for (let i = 0; i < values.length; i++) {
        console.log("i", i);

        c.beginPath();
        c.strokeStyle = COLORS[i];

        [x, y] = this.translate(i, this.x, this.prevValues[i]);
        c.moveTo(x, y);
        [x, y] = this.translate(i, this.x + 1, this.prevValues[i]);
        c.lineTo(x, y);
        if (this.prevValues[i] !== values[i]) {
          [x, y] = this.translate(i, this.x + 1, values[i]);
          c.lineTo(x, y);
        }
        c.stroke();
      }
    }
    this.prevValues = values;

    this.x++;
    if (DX * this.x >= this.width) {
      this.reset();
    }
  }

  translate(i, x, y) {
    return [x * DX, DY + i * 3 * DY + (y ? 0 : 1) * DY];
  }

  destroy() {}
}
