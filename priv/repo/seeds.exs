# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SocialCircle.Repo.insert!(%SocialCircle.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SocialCircle.Repo
import Ecto.Query

# Clear existing data in development
if Mix.env() == :dev do
  IO.puts("🧹 Clearing existing seed data...")
  # Add your schema deletions here when you have them
  # Repo.delete_all(SocialCircle.Posts.Post)
  # Repo.delete_all(SocialCircle.Accounts.User)
end

IO.puts("🌱 Seeding database with realistic social media data...")

# Seed Users (when you have the schema)
# users = [
#   %{
#     email: "john.doe@example.com",
#     username: "johndoe",
#     display_name: "John Doe",
#     bio: "Tech enthusiast and coffee lover ☕",
#     avatar_url: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=faces",
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   },
#   %{
#     email: "jane.smith@example.com", 
#     username: "janesmith",
#     display_name: "Jane Smith",
#     bio: "Designer | Traveler | Dog mom 🐕",
#     avatar_url: "https://images.unsplash.com/photo-1494790108755-2616b26c4622?w=150&h=150&fit=crop&crop=faces",
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   }
# ]
# 
# inserted_users = Enum.map(users, &Repo.insert!/1)

# Sample social media posts data (when you have the schema)
# posts = [
#   %{
#     platform: "twitter",
#     external_id: "1234567890123456789",
#     content: "Just launched my new social media platform! 🚀 #SocialCircle #Phoenix",
#     author_name: "John Doe",
#     author_handle: "@johndoe",
#     posted_at: ~N[2024-01-15 10:30:00],
#     like_count: 128,
#     share_count: 42,
#     comment_count: 15,
#     media_urls: [],
#     location: %{
#       name: "San Francisco, CA",
#       latitude: 37.7749,
#       longitude: -122.4194
#     },
#     hashtags: ["SocialCircle", "Phoenix"],
#     mentions: [],
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   },
#   %{
#     platform: "facebook",
#     external_id: "123456789_987654321",
#     content: "Excited about the future of social media aggregation! Check out this awesome sunset 🌅",
#     author_name: "Jane Smith",
#     author_handle: "jane.smith.123",
#     posted_at: ~N[2024-01-15 12:00:00],
#     like_count: 45,
#     share_count: 8,
#     comment_count: 12,
#     media_urls: ["https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800"],
#     location: %{
#       name: "Golden Gate Bridge",
#       latitude: 37.8199,
#       longitude: -122.4783
#     },
#     hashtags: ["sunset", "goldengatebridge"],
#     mentions: ["@johndoe"],
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   },
#   %{
#     platform: "instagram", 
#     external_id: "17841234567890123",
#     content: "Morning coffee and code ☕️💻 #developer #coffee #workfromhome",
#     author_name: "John Doe",
#     author_handle: "johndoe",
#     posted_at: ~N[2024-01-14 08:15:00],
#     like_count: 234,
#     share_count: 0, # Instagram doesn't have shares
#     comment_count: 23,
#     media_urls: [
#       "https://images.unsplash.com/photo-1461988320302-91bde64fc8e4?w=800",
#       "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800"
#     ],
#     location: %{
#       name: "Home Office",
#       latitude: 37.7849,
#       longitude: -122.4094
#     },
#     hashtags: ["developer", "coffee", "workfromhome"],
#     mentions: [],
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   },
#   %{
#     platform: "linkedin",
#     external_id: "activity:6890123456789012345",
#     content: "Thrilled to announce that our Phoenix application achieved 99.9% uptime this quarter! Here's what we learned about building resilient systems...",
#     author_name: "Jane Smith",
#     author_handle: "jane-smith-dev",
#     posted_at: ~N[2024-01-13 14:30:00],
#     like_count: 89,
#     share_count: 15,
#     comment_count: 6,
#     media_urls: [],
#     location: nil, # LinkedIn posts don't always have locations
#     hashtags: ["phoenix", "elixir", "devops", "reliability"],
#     mentions: ["@johndoe"],
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   }
# ]

# Generate more realistic data with timestamps over the last 30 days
sample_content = [
  "Working on some exciting new features! 🚀",
  "Beautiful day for coding in the park ☀️",
  "Just discovered this amazing Elixir library",
  "Phoenix LiveView continues to amaze me",
  "Coffee + Code = Perfect morning ☕️",
  "Debugging is like being a detective 🔍",
  "Clean code is a love letter to the future you",
  "Another day, another bug fixed 🐛➡️✨",
  "Pair programming session was incredibly productive",
  "Learning something new every day in this field"
]

sample_hashtags = [
  ["coding", "programming", "elixir"],
  ["phoenix", "liveview", "web"],
  ["coffee", "developer", "morning"],
  ["debugging", "problemsolving", "code"],
  ["learning", "growth", "tech"],
  ["opensource", "community", "sharing"]
]

platforms = ["twitter", "facebook", "instagram", "linkedin"]

# Generate 100 sample posts over the last 30 days
# posts_to_seed = for i <- 1..100 do
#   posted_days_ago = :rand.uniform(30)
#   posted_at = NaiveDateTime.utc_now()
#     |> NaiveDateTime.add(-posted_days_ago * 24 * 3600, :second)
#     |> NaiveDateTime.add(:rand.uniform(24 * 3600), :second)
# 
#   %{
#     platform: Enum.random(platforms),
#     external_id: "seed_#{i}_#{:rand.uniform(999999)}",
#     content: Enum.random(sample_content),
#     author_name: Enum.random(["John Doe", "Jane Smith", "Alex Johnson", "Sam Wilson"]),
#     author_handle: Enum.random(["johndoe", "janesmith", "alexj", "samw"]),
#     posted_at: posted_at,
#     like_count: :rand.uniform(500),
#     share_count: :rand.uniform(100),
#     comment_count: :rand.uniform(50),
#     media_urls: if(:rand.uniform(3) == 1, do: ["https://picsum.photos/800/600?random=#{i}"], else: []),
#     hashtags: Enum.random(sample_hashtags),
#     mentions: if(:rand.uniform(4) == 1, do: ["@#{Enum.random(["johndoe", "janesmith"])}"], else: []),
#     inserted_at: NaiveDateTime.utc_now(),
#     updated_at: NaiveDateTime.utc_now()
#   }
# end

# all_posts = posts ++ posts_to_seed
# Enum.each(all_posts, &Repo.insert!/1)

IO.puts("✅ Database seeded successfully!")
IO.puts("📊 Ready for development with realistic social media data")
IO.puts("🔧 Uncomment the relevant sections when you have your schemas ready")
