import RealtimeLineChart from "./analyze/line_chart";

export const LineChartHook = {
  mounted() {
    this.chart = new RealtimeLineChart(this.el);
    this.handleEvent("datapoint", ({ value }) => {
      this.chart.addPoint(value);
    });
    this.handleEvent("reset", () => {
      this.chart.reset();
    });
  },
};
