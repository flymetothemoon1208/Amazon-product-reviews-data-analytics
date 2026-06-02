const copyButton = document.querySelector("#copyLink");
const copyStatus = document.querySelector("#copyStatus");

async function copyCurrentLink() {
  const url = window.location.href;

  try {
    await navigator.clipboard.writeText(url);
    copyStatus.textContent = "Page link copied.";
  } catch {
    copyStatus.textContent = url;
  }

  window.clearTimeout(copyCurrentLink.timer);
  copyCurrentLink.timer = window.setTimeout(() => {
    copyStatus.textContent = "";
  }, 2400);
}

copyButton?.addEventListener("click", copyCurrentLink);
