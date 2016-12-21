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
      state *(STATES - [INACTIVE])

      event :activate do
        before do
        end
        transitions from: INACTIVE, to: ACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :deactivate do
        before do
        end
        transitions from: ACTIVE, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :delete do
        before do
        end
        transitions from: UNDELETEDS, to: DELETED
        after do
          touch :state_changed_at
        end
      end
    end

    scope :undeleted, -> { where(state: UNDELETEDS) }

    attr_accessor :active

    before_create do
      self.state_changed_at = created_at
    end

    before_save do
      if !active? && active.to_s == 'true'
        activate!
      elsif !inactive? && active.to_s == 'false'
        deactivate!
      end
    end

  end

end
