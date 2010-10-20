class Candidate < Monarch::Model::Record
  column :body, :string
  column :election_id, :key
  column :creator_id, :key
  column :position, :integer

  belongs_to :election
  belongs_to :creator, :class_name => "User"
  has_many :rankings

  def before_create
    self.creator ||= current_user
  end

  def after_create
    other_candidates.each do |other_candidate|
      Majority.create({:winner => self, :loser => other_candidate, :election_id => election_id})
      Majority.create({:winner => other_candidate, :loser => self, :election_id => election_id})
    end

    victories_over(election.negative_candidate_ranking_counts).update(:pro_count => :times_ranked)
    victories_over(election.positive_candidate_ranking_counts).update(:con_count => :times_ranked)
    defeats_by(election.positive_candidate_ranking_counts).update(:pro_count => :times_ranked)
    defeats_by(election.negative_candidate_ranking_counts).update(:con_count => :times_ranked)

    election.compute_global_ranking
  end

  def before_destroy
    puts "destroying candidate #{id}"
    rankings.each(&:destroy)
    winning_majorities.each(&:destroy)
    losing_majorities.each(&:destroy)
  end

  def other_candidates
    election.candidates.where(Candidate[:id].neq(id))
  end

  def victories_over(other_candidate_ranking_counts)
    winning_majorities.
      join(other_candidate_ranking_counts).
        on(:loser_id => :candidate_id)
  end

  def defeats_by(other_candidate_ranking_counts)
    losing_majorities.
      join(other_candidate_ranking_counts).
        on(:winner_id => :candidate_id)
  end

  def winning_majorities
    election.majorities.where(:winner_id => id)
  end

  def losing_majorities
    election.majorities.where(:loser_id => id)
  end
end