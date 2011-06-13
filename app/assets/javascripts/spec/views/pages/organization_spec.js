//= require spec/spec_helper

describe("Views.Pages.Organization", function() {

  var organizationPage;
  beforeEach(function() {
    organizationPage = Views.Pages.Organization.toView();
  });

  describe("when the id is assigned", function() {
    beforeEach(function() {
      stubAjax();
    });

    describe("when the organization exists in the local repository", function() {
      it("assigns the organization", function() {
        var org1 = Organization.createFromRemote({id: 1, name: "Watergate"});
        organizationPage.id(org1.id());
        expect(organizationPage.organization()).toBe(org1);
      });
    });

    describe("when the organization does not exist in the local repository", function() {
      it("navigates to the organization page for Hyperarchy Social", function() {
        var socialOrg = Organization.createFromRemote({id: 1, social: true});
        organizationPage.id(99);
        expect(organizationPage.organization()).toBe(socialOrg);
      });
    });
  });

  describe("when the organization is assigned", function() {
    beforeEach(function() {
      attachLayout();
    });

    it("assigns the id and fetches the organization's elections", function() {
      var user, organization, election1, election2;

      clearServerTables();
      user = login();
      usingBackdoor(function() {
        organization = Organization.create();
        user.memberships().create({organizationId: organization.id()});
        createMultiple({
          count: 17,
          tableName: 'elections',
          fieldValues: { organizationId: organization.id() }
        });
        Election.clear();
      });

      waitsFor("elections to be fetched", function(complete) {
        organizationPage.organization(organization).success(complete);
        expect(organizationPage.id()).toBe(organization.id());
        expect(organization.elections().size()).toBe(0);
      });

      runs(function() {
        expect(organization.elections().size()).toBe(16);
        var electionsList = organizationPage.electionsList;
        organization.elections().each(function(election) {
          expect(electionsList).toContain("li:contains('" + election.body() + "')");
        });

        var election = organization.elections().first();
        electionsList.find("li:contains('" + election.body() + "')").click();
        expect(Path.routes.current).toBe("/elections/" + election.id());
      });
    });
  });
});