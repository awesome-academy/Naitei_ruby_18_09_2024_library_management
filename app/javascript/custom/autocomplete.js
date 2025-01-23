document.addEventListener("turbo:load", function () {
  const searchInput = document.getElementById("search_bar");
  const styledOverlay = document.getElementById("styled_overlay");

  if (searchInput && styledOverlay) {
    searchInput.addEventListener("input", function () {
      const query = searchInput.value.trim();

      if (query.length > 1) {
        fetchSuggestions(query);
      } else {
        clearAutocomplete();
      }
    });
  }

  function fetchSuggestions(query) {
    fetch(`/books/autocomplete?query=${encodeURIComponent(query)}`)
      .then(response => response.json())
      .then(data => {
        displaySuggestion(query, data);
      });
  }

  function displaySuggestion(query, suggestions) {
    if (suggestions.matched_part != null) {
      styledOverlay.innerHTML = highlightText(suggestions.matched_part);
      styledOverlay.style.paddingLeft = `${measureTextWidth(query, searchInput)}px`;
      styledOverlay.classList.remove("hidden");
    } else {
      clearAutocomplete();
    }
  }

  function clearAutocomplete() {
    styledOverlay.innerHTML = "";
    styledOverlay.classList.add("hidden");
  }

  function highlightText(matchedPart) {
    return `<span class="text-gray-500">${matchedPart}</span>`;
  }

  function measureTextWidth(text, inputElement) {
    const tempSpan = document.createElement("span");
    tempSpan.style.position = "absolute";
    tempSpan.style.whiteSpace = "nowrap";
    tempSpan.style.visibility = "hidden";
    tempSpan.style.font = getComputedStyle(inputElement).font;
    tempSpan.textContent = text;

    document.body.appendChild(tempSpan);
    const textWidth = tempSpan.offsetWidth;
    document.body.removeChild(tempSpan);

    return textWidth + 18;
  }
});
