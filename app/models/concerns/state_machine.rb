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
        transitions from: INACTIVE, to: ACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :deactivate do
        transitions from: ACTIVE, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :delete do
        transitions from: UNDELETEDS, to: DELETED
        after do
          touch :state_changed_at
        end
      end
    end

  end

end
