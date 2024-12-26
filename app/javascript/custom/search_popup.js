document.addEventListener("turbo:load", function () {
  const filterButton = document.getElementById("search_popup_btn");
  const popup = document.getElementById("search_popup");

  if(filterButton){
    filterButton.addEventListener("click", function () {
      popup.classList.toggle("hidden");
    });
  }

  if(popup){
    document.addEventListener("click", function (event) {
      if (!popup.contains(event.target) && !filterButton.contains(event.target)) {
        popup.classList.add("hidden");
      }
    });
  }
});
