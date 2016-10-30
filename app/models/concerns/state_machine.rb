module StateMachine

  extend ActiveSupport::Concern

  ACTIVE = :active
  INACTIVE = :inactive
  DELETED = :deleted
  STATES = [INACTIVE, ACTIVE, DELETED]
  UNDELETEDS = STATES - [DELETED]

  included do
    include AASM

    aasm(column: :state) do
      state INACTIVE, initial: true
      state ACTIVE, DELETED

      event :activate do
        before do
          self.state_transition = nil
        end
        transitions from: INACTIVE, to: ACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :deactivate do
        before do
          self.state_transition = nil
        end
        transitions from: ACTIVE, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :delete do
        before do
          self.state_transition = nil
        end
        transitions from: UNDELETEDS, to: DELETED
        after do
          touch :state_changed_at
        end
      end
    end

    scope :undeleteds, -> { where(state: UNDELETEDS) }

    attr_accessor :state_transition

    before_create do
      self.state_changed_at = created_at
    end

    before_save do
      send("#{state_transition}!") if state_transition.present?
    end

  end

end
