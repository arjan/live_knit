import "../css/app.css";
import "phoenix_html";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { LineChartHook } from "./analyze";
import { PatCanvas } from "./pat";

const hooks = {
  LineChartHook,
  PatCanvas,
  ImageUpload: {
    mounted() {
      document.getElementById("fileUpload").addEventListener("change", (e) => {
        var reader = new FileReader();
        reader.onload = () => {
          this.pushEvent("image-data", reader.result);
        };
        reader.readAsDataURL(e.target.files[0]);
      });
    },
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks,
});

liveSocket.connect();

liveSocket.disableDebug();
window.liveSocket = liveSocket;
