window.formatCount = function(n){
  const num = Number(n) || 0;
  const lang = (typeof getLang === "function" ? getLang() : "ru");
  if (num >= 1000000) {
    const v = num / 1000000;
    return lang === "ru"
      ? v.toFixed(v >= 10 ? 0 : 1).replace(".", ",") + " млн"
      : v.toFixed(v >= 10 ? 0 : 1) + "M";
  }
  if (num >= 1000) {
    const v = num / 1000;
    return lang === "ru"
      ? v.toFixed(v >= 10 ? 0 : 1).replace(".", ",") + " тыс."
      : v.toFixed(v >= 10 ? 0 : 1) + "K";
  }
  return String(num);
};

window.loadYouTubeStats = async function(){
  const subsEl = document.getElementById("yt-subs");
  const videosEl = document.getElementById("yt-videos");
  if (!subsEl || !videosEl) return;

  function paint(stats){
    if (!stats) return;
    subsEl.textContent = formatCount(stats.subscriberCount);
    videosEl.textContent = formatCount(stats.videoCount);
    subsEl.dataset.raw = stats.subscriberCount;
    videosEl.dataset.raw = stats.videoCount;
  }

  try {
    const res = await fetch("yt-stats.json", { cache: "no-store" });
    if (!res.ok) throw new Error("yt-stats.json " + res.status);
    paint(await res.json());
  } catch (err) {
    console.warn("YouTube stats file unavailable");
  }
};
