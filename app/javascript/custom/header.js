document.addEventListener("turbo:load", function() {
  let account = document.querySelector("#profile_picture");
  if (account){
    account.addEventListener("click", function(event) {
      event.preventDefault();
      let menu = document.querySelector("#drop_down");
      menu.classList.toggle("hidden");
    });
  }
});

window.setLocale = function setLocale(locale) {
  const currentUrl = new URL(window.location.href);
  const pathSegments = currentUrl.pathname.split("/").filter(segment => segment);

  if (["vi", "en"].includes(pathSegments[0])) {
    pathSegments[0] = locale;
  } else {
    pathSegments.unshift(locale);
  }

  currentUrl.pathname = "/" + pathSegments.join("/");
  window.location.href = currentUrl.toString();
}
