class Balance < ApplicationRecord
  extend DirtyRead
  extend PhantomRead
  extend NonRepeatableRead
  extend SerializationAnomaly

  # Locking issues

  extend Deadlock

  validates :created_at, comparison: { less_than: Time.now }, on: :update
end
