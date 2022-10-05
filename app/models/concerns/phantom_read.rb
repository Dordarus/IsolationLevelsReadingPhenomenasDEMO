module PhantomRead
  # Lets use our default MySQL isolation level here

  def phantom_read_select_example
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
        puts 'T2 started'

        puts '=' * 100
        puts '[T2] Before T1 committed'
        puts "[T2] #{Balance.where('amount >= 100').count} account/-s have >= 100$" # Dirty read here possible for READ_UNCOMMITTED isolation level
        puts '=' * 100

        sleep 0.6 # right after T1 committed

        puts '=' * 100
        puts '[T2] Lets return amount again, after T1 committed'
        puts "[T2] Your balance is #{Balance.first.amount}$" # Non-Repeatable Read here possible for READ_UNCOMMITTED and READ_COMMITTED isolation level
        puts '=' * 100

        puts '=' * 100
        puts '[T2] After T1 committed'
        puts "[T2] #{Balance.where('amount >= 100').count} account/-s have >= 100$" # Phantom read here possible for READ_UNCOMMITTED and READ_COMMITTED isolation level
        # Reading phantom rows not possible fot REPEATABLE READ because each reading query will return same count of rows.
        puts '=' * 100

        puts 'T2 committed'
      end
    end

    threads.map(&:join)

    puts '=' * 100
    puts "[Final] Your balance is #{Balance.first.amount}$"
    puts '=' * 100

    # Process.waitall
  end

  def phantom_read_after_update_example
    Balance.first.update!(amount: 100)
    threads = []

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :read_committed) do
        puts 'T1 started'

        puts '=' * 100
        puts "[T1] You have #{Balance.first.amount}$"
        puts '[T1] Lets spend some money! -10$'
        puts '=' * 100
        balance = Balance.first
        balance.amount -= 10
        balance.save

        puts '=' * 100
        puts '[T1] Lets return amount again, before T1 committed'
        puts "[T1] Your balance is #{Balance.first.amount}$" # Non-Repeatable Read here possible for READ_UNCOMMITTED and READ_COMMITTED isolation level
        puts '=' * 100

        sleep 1
        puts 'T1 committed'
      end
    end

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :read_committed) do # repeatable_read
        sleep 0.6 # before T2 committed
        puts 'T2 started'

        puts '=' * 100
        puts '[T2] Lets return amount again, before T1 committed'
        puts "[T2] Your balance is #{Balance.first.amount}$" # Non-Repeatable Read here possible for READ_UNCOMMITTED and READ_COMMITTED isolation level
        puts '=' * 100

        sleep 0.8 # right after T1 committed

        puts '=' * 100
        puts '[T2] Lets spend some money! -10$'
        puts '=' * 100
        balance = Balance.first
        balance.amount -= 10
        balance.save

        # puts '=' * 100
        # puts '[T2] Lets remove account'
        # puts '=' * 100
        # Balance.first.destroy # Phantom read here possible for REPEATABLE_READ
        puts '=' * 100
        puts '[T2] Lets return amount again, after T1 committed'
        puts "[T2] Your balance is #{Balance.first&.amount}$" # Non-Repeatable Read here possible for READ_UNCOMMITTED and READ_COMMITTED isolation level
        # 100 - 10 = 80$ here possible for READ_COMMITTED and READ_UNCOMMITTED isolation level
        puts '=' * 100

        puts 'T2 committed'
      end
    end

    threads.map(&:join)
  end

  def phantom_read_v2
    Balance.first.update(amount: 100)
    threads = []

    threads << Thread.new do
      # fork do
      Balance.transaction do
        balance = Balance.first
        balance.amount += 600
        balance.save

        sleep 1
      end
    end

    threads << Thread.new do
      # fork do
      Balance.transaction do
        sleep 0.5
        balance = Balance.first
        balance.amount += 1000
        balance.save
      end
    end

    threads.map(&:join)
    # Process.waitall
  end
end
