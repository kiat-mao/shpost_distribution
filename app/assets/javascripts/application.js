// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.all
//= require wice_grid
//= require autocomplete-rails


//= require twitter/bootstrap
//= require turbolinks
//= require_tree .
// var ready;

function ajaxsuppliers() {
  jQuery.railsAutocomplete.options.noMatchesLabel = "没有相应记录"
	$('#supplier_name').bind('railsAutocomplete.select', function(event, data){
    /* Do something here */
    var sid = "#"+data.item.obj+"_supplier_id";
    $(sid).val(data.item.id);
  });
}

// $(document).ready(ready);
// $(document).on('page:load', ready);

//For WiceGrid 3.6 not work on turbolink 5.0
// $(document).on('turbolinks:load', function(){
//     initWiceGrid(); 
// });
