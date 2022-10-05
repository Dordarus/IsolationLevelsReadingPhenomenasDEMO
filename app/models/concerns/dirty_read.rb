module DirtyRead
  def dirty_read
    Balance.first.update!(amount: 100)
    threads = []

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :read_uncommitted) do
        puts 'T1 started'

        puts '=' * 100
        puts "[T1] You have #{Balance.first.amount}$"
        puts '[T1] Lets spend some money! -10$'
        puts '=' * 100

        balance = Balance.first
        balance.amount -= 10
        balance.save
        sleep 1
        balance.created_at = Time.now + 1.day
        balance.save

        puts 'T1 committed'
      end
    end

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :read_committed) do
        sleep 0.5
        puts 'T2 started'

        puts '=' * 100
        puts '[T2] You trying to check your balance'
        puts "[T2] Your balance is #{Balance.first.amount}$" # Dirty read here possible for READ_UNCOMMITTED isolation level
        puts '=' * 100

        puts 'T2 committed'
      end
    end

    puts '=' * 100
    puts '[Final] Transaction 1 finished!'
    puts "[Final] Your balance is #{Balance.first.amount}$"
    puts '=' * 100

    threads.map(&:join)

    # Process.waitall
  end
end
