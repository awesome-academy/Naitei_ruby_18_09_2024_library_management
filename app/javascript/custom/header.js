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
