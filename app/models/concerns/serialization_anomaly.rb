module SerializationAnomaly
  # DeadLock happened in serialization isolation level
  def serialization_anomaly
    Balance.first.update!(amount: 70)
    threads = []

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :serializable) do
        sum = Balance.sum(:amount)

        puts '=' * 100
        puts '[T1] Sum of all amounts'
        puts "[T1] #{sum}"
        puts '=' * 100

        puts '=' * 100
        puts '[T1] Lets create new row where will stor sum data'
        Balance.create(amount: sum, owner: 'sum')
        puts Balance.pluck(:amount)
        puts '=' * 100
      end
    end

    threads << Thread.new do
      # fork do
      Balance.transaction(isolation: :serializable) do
        sum = Balance.sum(:amount)

        puts '=' * 100
        puts '[T2] Sum of all amounts'
        puts "[T2] #{sum}"
        puts '=' * 100

        puts '=' * 100
        puts '[T2] Lets create new row where will stor sum data'
        Balance.create(amount: sum, owner: 'sum')
        puts Balance.pluck(:amount)
        puts '=' * 100
      end
    end

    threads.map(&:join)

    # Process.waitall
  end
end
