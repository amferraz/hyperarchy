_.constructor('Views.Layout.OrganizationsMenu', View.Template, {
  content: function() { with(this.builder) {
    div({id: "organizations-menu"}, function() {
      a({id: "add-organization-link"}, "Add Your Organization").ref('addOrganizationLink').click("showAddOrganizationForm");
      subview("dropdownMenu", Views.Layout.DropdownMenu, {
        linkContent: function() {
          this.builder.text("Organizations");
        },

        menuContent: function() {
          this.builder.subview('organizationsList', Views.Components.SortedList, {
            buildElement: function(organization) {
              return $("<li><a>" + organization.name() +"</a></li>").click(function() {
                History.pushState(null, null, organization.url());
              });
            }
          });
          this.builder.a({id: "add-organization-menu-item"}, "Add Your Organization").ref('addOrganizationLink').click("showAddOrganizationForm");
        }
      });
    });
  }},

  viewProperties: {
    initialize: function() {
      this.userSubscriptions = new Monarch.SubscriptionBundle();
      this.dropdownMenu.showAddOrganizationForm = this.hitch('showAddOrganizationForm');
    },

    attach: function() {
      Application.onCurrentUserChange(function(user) {
        this.showOrHideDropdownLink();
        this.userSubscriptions.destroy();
        this.userSubscriptions.add(user.organizations().onInsert(this.hitch('showOrHideDropdownLink')));
        this.userSubscriptions.add(user.organizations().onRemove(this.hitch('showOrHideDropdownLink')));
        this.dropdownMenu.organizationsList.relation(user.organizations());
      }, this);
    },

    showOrHideDropdownLink: function() {
      if (Application.currentUser().organizations().size() > 1) {
        this.dropdownMenu.show();
        this.addOrganizationLink.hide();
      } else {
        this.dropdownMenu.hide();
        this.addOrganizationLink.show();
      }
    },

    showAddOrganizationForm: function() {
      Application.signupForm.show();
      Application.signupForm.showOrganizationSection();
    }
  }
});

