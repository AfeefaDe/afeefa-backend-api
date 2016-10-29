module StateMachine

  extend ActiveSupport::Concern

  included do
    include AASM

    ACTIVE = :active
    INACTIVE = :inactive
    DELETED = :deleted
    STATES = [INACTIVE, ACTIVE, DELETED]
    UNDELETEDS = STATES - [DELETED]

    aasm(column: :state) do
      state INACTIVE, initial: true
      state ACTIVE, DELETED

      event :activate do
        transitions from: INACTIVE, to: ACTIVE
      end

      event :deactivate do
        transitions from: ACTIVE, to: INACTIVE
      end

      event :delete do
        transitions from: UNDELETEDS, to: DELETED
      end
    end

  end

end
