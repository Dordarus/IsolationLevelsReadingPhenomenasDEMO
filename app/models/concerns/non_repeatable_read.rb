module NonRepeatableRead
  def non_repeatable_read
    Balance.first.update!(amount: 100)
    threads = []

    threads << Thread.new do
      # fork do
      Balance.transaction do
        puts 'T1 started'

        puts '=' * 100
        puts "[T1] You have #{Balance.first.amount}$"
        puts '[T1] Lets spend some money! -10$'
        puts '=' * 100
        balance = Balance.first
        balance.amount -= 10
        balance.save
        sleep 1

        puts 'T1 committed'
      end
    end

    threads << Thread.new do
      # fork do
      Balance.transaction do # repeatable_read
        sleep 0.6 # before T2 committed
        puts 'T1 started'

        puts '=' * 100
        puts '[T2] Before T1 committed'
        puts "[T2] #{Balance.where('amount >= 100').count} account/-s have >= 100$" # Dirty read here possible for READ_UNCOMMITTED isolation level
        puts '=' * 100

        sleep 0.6 # right after T1 committed

        puts '=' * 100
        puts '[T2] Lets return amount again, after T1 committed'
        puts "[T2] Your balance is #{Balance.first.amount}$" # Non-Repeatable Read here possible for READ_UNCOMMITTED and READ_COMMITTED isolation level
        puts '=' * 100

        puts 'T1 committed'
      end
    end

    threads.map(&:join)

    puts '=' * 100
    puts '[Final] Transaction 1 and 2 finished!'
    puts "[Final] Your balance is #{Balance.first.amount}$"
    puts '=' * 100

    # Process.waitall
  end
end
