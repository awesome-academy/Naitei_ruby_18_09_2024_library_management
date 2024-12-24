document.addEventListener("turbo:load", function() {
  let toggle = document.querySelector("#password_toggle");
  if (toggle){
    toggle.addEventListener("click", function(event) {
      event.preventDefault();
      let passwordField = document.querySelector("#user_password");
      if (passwordField){
        const type = passwordField.type === "password" ? "text" : "password";
        passwordField.type = type;
      }
    });
  }
});
