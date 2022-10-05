module Deadlock
  def deadlock
    Balance.first.update!(amount: 100)
    threads = []

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :serializable) do
        puts 'T1 started'

        puts '=' * 100
        puts "[T1] You have #{Balance.first.amount}$"
        puts '[T1] Lets spend some money! -10$'
        puts '=' * 100

        balance = Balance.first
        balance.amount -= 10
        balance.save

        puts 'T1 committed'
      end
    end

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :serializable) do
        puts 'T2 started'

        puts '=' * 100
        puts "[T1] You have #{Balance.first.amount}$"
        puts '[T1] Lets spend some money! -10$'
        puts '=' * 100

        balance = Balance.first
        balance.amount -= 10
        balance.save

        puts 'T2 committed'
      end
    end

    threads.map(&:join)

    # Process.waitall
  end
end
