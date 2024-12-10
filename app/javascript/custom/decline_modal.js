document.addEventListener("turbo:load", () => {
  const popup = document.querySelector("#popup-form");
  const closePopup = document.querySelector("#close-popup");
  const decline_btn = document.querySelector("#decline_btn")

  if(popup && decline_btn)
    decline_btn.addEventListener("click", () => {
      popup.classList.remove("hidden");
    });

  if(closePopup)
    closePopup.addEventListener("click", () => {
      popup.classList.add("hidden");
    });
});
