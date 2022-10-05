require 'faker'

3.times do
  Balance.create(amount: 100, owner: Faker::TvShows::RickAndMorty.character)
end
