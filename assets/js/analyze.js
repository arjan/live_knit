import RealtimeLineChart from "./analyze/line_chart";

export const LineChartHook = {
  mounted() {
    this.chart = new RealtimeLineChart(this.el);
    this.handleEvent("datapoint", ({ time, value }) => {
      this.chart.addPoint(time, value);
    });
    this.handleEvent("reset", () => {
      this.chart.reset();
    });
  },
};
