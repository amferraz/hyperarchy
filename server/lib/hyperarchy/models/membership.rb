class Membership < Monarch::Model::Record
  column :organization_id, :key
  column :user_id, :key
  column :invitation_id, :key
  column :role, :string
  column :pending, :boolean, :default => true

  belongs_to :organization
  belongs_to :user
  belongs_to :invitation

  attr_accessor :email_address, :full_name

  def before_create
    if user = User.find(:email_address => email_address)
      self.user = user
    else
      self.invitation =
        Invitation.find(:sent_to_address => email_address) ||
          Invitation.create!(:sent_to_address => email_address,
                             :full_name => full_name,
                             :inviter => current_user)
    end
  end

  def after_create
    Mailer.send(
      :to => email_address,
      :from => "admin@hyperarchy.com",
      :subject => invite_email_subject,
      :body => invite_email_body
    )
  end

  protected
  def invite_email_subject
    "#{current_user.full_name} has invited you to join #{organization.name} on Hyperarchy"
  end

  def invite_email_body
    if invitation
      %[Visit #{Mailer.base_url}/signup?invitation_code=#{invitation.guid} to sign up.]
    else
      %[Visit #{Mailer.base_url}/confirm_membership/#{id} to become a member of #{organization.name}.]
    end
  end
end
