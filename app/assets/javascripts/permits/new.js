var selected_projects = [];

$(document).ready(function() {

window.addEventListener("load", function(event) {
  console.log("page loaded!");
  var state = history.state;
  history.state = null;
  console.log("state after setting history.state");
  console.log(state);
  history.replaceState(null, null, null);
  console.log("state after replacing state");
  console.log(state);
    if (state) {
    selected_projects = state["selected_projects"];
    for (i = 0; i < selected_projects.length; i++) {
      selectProject(selected_projects[i]);

      // @TODO: may want to re-visit to see why once I move the following to toggleProject, proj doesn't get selected
      selectedCheckBox = ("permit_selected_").concat(selected_projects[i]).replace("-", "_");
      document.getElementById(selectedCheckBox).checked = true;
      console.log("finish popstate in load");
    }
  }
});

$("#new_permit_submit").click(function(e){
  console.log("before preventing default");
  e.stopPropagation();
  e.preventDefault();
  console.log("before saving projects");
  saveProjects();
  console.log("before submiting");
  $('#new_permit').submit();
 });

  // trigger when user clicks any of the "select a project" buttons
  $ (".project").each(function(i) {

    // just focus on the button the user clicked
    $(this).click(function() {

      // get the id of the clicked button button, which will tell us what kind of project the user picked
      clickedButton = $(this).attr("id");

      // add in selected_projects array
      proj_index = selected_projects.indexOf(clickedButton);
      if (proj_index == -1) {
        // add item to array
        selected_projects.push(clickedButton);
        selectProject(clickedButton);
      } else {
        // remove item from array
        selected_projects.splice(proj_index, 1);
        unselectProject(clickedButton);
      }

      console.log(selected_projects);
    
    });
  });
});

// window.addEventListener('popstate', function(event) {
//   console.log("in popstate event");
//   console.log("poping state triggered");
//   console.log(event.state);
//   if (event.state) {
//     selected_projects = event.state["selected_projects"];
//     for (i = 0; i < selected_projects.length; i++) {
//       selectProject(selected_projects[i]);

//       // @TODO: may want to re-visit to see why once I move the following to toggleProject, first page behaves super weird
//       selectedCheckBox = ("permit_selected_").concat(selected_projects[i]).replace("-", "_");
//       document.getElementById(selectedCheckBox).checked = true;
//       console.log("finish popstate in listener");
//     }
//   }
// });


function selectProject(project)
{
  toggleProject(project, true);
}

function unselectProject(project)
{
  toggleProject(project, false);
}

function toggleProject(project, toggle)
{
  // grab the class for the clickedButton, so we can add the success class and change its color
  clickedButtonClass = (".pick-").concat(project);
  // give the clicked button the success class, so it will change color
  $(clickedButtonClass).toggleClass("btn-success", toggle);

  // turn the id we got from clickedButton into a class, so we can show the correct "Your Project" sidebar icon
  chosenProject = (".").concat(project);
  // show the correct "Your Project" icon in sidebar
  $(chosenProject).toggleClass("displayed", toggle);
}

function saveProjects()
{
  console.log("saving projects");
  //debugger
  console.log("pushing states");
  var stateObj = {};
  stateObj.selected_projects = selected_projects;
  history.pushState(stateObj, "Homebase", document.URL);
  console.log(stateObj);
}

