class Ability
  include CanCan::Ability

  def initialize(user)
    
    if user && user.persisted? # Logged in user
      if user.admin?
        can :manage, :all

      else
        can [:new, :create], Post
        can :destroy, Post, user_id: user.id

        indexable_condition = <<-EOC
restricted = ? OR posts.user_id = ? OR (restricted = ? AND EXISTS
  (SELECT * FROM collaborations WHERE collaborations.post_id = posts.id AND collaborations.user_id = ?))
        EOC
        can [:index, :show], Post, [indexable_condition, false, user.id, true, user.id] do |post|
          !post.restricted? || post.user_id == user.id ||
            (post.restricted? &&
             post.collaborations.where(user_id: user.id).present?)
        end

        editable_condition = <<-EOC
posts.user_id = ? OR EXISTS
  (SELECT * FROM collaborations WHERE collaborations.post_id = posts.id AND collaborations.user_id = ?)
        EOC
        can [:edit, :update], Post, [editable_condition, user.id, true, user.id] do |post|
          post.user_id == user.id ||
             post.collaborations.where(user_id: user.id).present?
        end
      end

    else # Guest user
      can [:show, :index], Post, restricted: false

    end


    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
