// Menü-Einträge definieren
var MenuItems = [
  { Text: "Home", Link: "index.html" },
  { Text: "EPG", Link: "epg.html" },
  { Text: "Stream Status", Link: "streamstatus.html" },
  { Text: "Tuner Status", Link: "tunerstatus.html" },
  { Text: "Unicable Settings", Link: "scif.html" },
  { Text: "LNB Settings", Link: "lnbsettings.html" },
  { Text: "System Settings", Link: "system.html" },
  { Text: "Network Settings", Link: "network.html" },
  { Text: "Multicast Setup", Link: "multicast.html" },
  { Text: "Channel Lists", Link: "channellists.html" },
  { Text: "Update", Link: "updateserver.html" },
  { Text: "Reboot", Link: "reboot.html" },
  { Text: "Hardware Monitor", Link: "monitor.html" },
  { Text: "Licenses", Link: "licenses.html" }
];

function CreateMenu() {
  var currentPath = window.location.pathname.split("/").pop();
  if (currentPath === "") { currentPath = "index.html"; }

  var html = '<ul class="menu-list">';

  // Normale Menüpunkte generieren
  for (var i = 0; i < MenuItems.length; i++) {
    if (currentPath === MenuItems[i].Link) {
      html += '<li class="menucur"><span>' + MenuItems[i].Text + '</span></li>';
    } else {
      html += '<li><a href="/' + MenuItems[i].Link + '">' + MenuItems[i].Text + '</a></li>';
    }
  }

  // --- DER NEUE DARK MODE SCHALTER AN DER MENÜ-BASIS ---
  html += '<li class="dark-mode-toggle-item">';
  html += '  <button onclick="ToggleDarkMode()" class="btn-dark-toggle" id="darkToggleBtn">';
  html += '    <span class="mode-icon">🌓</span> <span id="darkToggleText">Dark Mode</span>';
  html += '  </button>';
  html += '</li>';

  html += '</ul>';
  document.write(html);

  // Initialisiert das Theme sofort beim Laden der Seite
  ApplyTheme();
}

// Logik für das Umschalten und Speichern
function ToggleDarkMode() {
  var currentTheme = localStorage.getItem("theme");
  if (currentTheme === "dark") {
    localStorage.setItem("theme", "light");
  } else {
    localStorage.setItem("theme", "dark");
  }
  ApplyTheme();
}

function ApplyTheme() {
  var savedTheme = localStorage.getItem("theme");
  var prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  var textElem = document.getElementById("darkToggleText");
  
  // Wenn manuell "dark" gewählt wurde ODER kein Speicher existiert aber das System "dark" meldet
  if (savedTheme === "dark" || (!savedTheme && prefersDark)) {
    document.documentElement.classList.add("dark-theme");
    if(textElem) textElem.innerHTML = "Light Mode";
  } else {
    document.documentElement.classList.remove("dark-theme");
    if(textElem) textElem.innerHTML = "Dark Mode";
  }
}

var browserLanguage = (navigator.language || navigator.userLanguage || "en").substr(0, 2);

