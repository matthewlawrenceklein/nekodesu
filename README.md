# 猫です (Nekodesu) - Japanese Reading Comprehension Practice

A Rails application that generates personalized Japanese dialogues based on your WaniKani vocabulary level. Practice reading comprehension with AI-generated content tailored to your current knowledge.

## Features

### 🎯 Core Features
- **WaniKani Integration**: Automatically syncs your vocabulary and kanji at or below your current level
- **AI-Powered Dialogues**: Generates natural Japanese conversations using OpenRouter AI (Claude 3.5 Sonnet)
- **Smart Question System**: 10 comprehension questions per dialogue, 4 randomly selected per attempt
- **Progress Tracking**: Track your scores, completion rate, and improvement over time
- **Retry System**: Practice the same dialogue multiple times with different random questions

### 🎨 User Experience
- **Dark Mode**: Full dark mode support with persistent preference
- **Responsive Design**: Beautiful Tailwind CSS interface that works on all devices
- **Real-time Generation**: Generate new dialogues on-demand through the UI
- **Difficulty Levels**: Beginner (N5), Intermediate (N4-N3), Advanced (N2-N1)

### ⚙️ Technical Features
- **Background Jobs**: Scheduled syncs and async dialogue generation with GoodJob
- **Level-Based Content**: Only uses vocabulary and kanji you've learned
- **Grammar Matching**: Dialogue complexity matches JLPT level expectations
- **Robust Parsing**: Handles AI response variations and formatting issues

## Tech Stack

- **Framework**: Rails 8.1
- **Database**: PostgreSQL 16
- **Job Processing**: GoodJob (PostgreSQL-backed)
- **Views**: ERB with Tailwind CSS
- **HTTP Client**: Faraday
- **AI Integration**: OpenRouter gem
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker and Docker Compose
- API Keys:
  - [WaniKani API Key](https://www.wanikani.com/settings/personal_access_tokens) - Required for vocabulary sync
  - [OpenRouter API Key](https://openrouter.ai/keys) - Required for AI dialogue generation

## Getting Started

### 1. Clone and Setup Environment

```bash
# Copy the example environment file
cp env.example .env

# Edit .env and add your API keys
# WANIKANI_API_KEY=your_wanikani_key_here
# OPENROUTER_API_KEY=your_openrouter_key_here
```

### 2. Build and Start Services

```bash
# Build the Docker images
docker compose build

# Start all services (web, worker, database)
docker compose up -d
```

### 3. Setup Database

```bash
# Create and migrate the database
docker compose exec web rails db:create db:migrate

# Create a user (in Rails console)
docker compose exec web rails console
# > User.create!(email: "your@email.com", wanikani_api_key: ENV['WANIKANI_API_KEY'], openrouter_api_key: ENV['OPENROUTER_API_KEY'])
```

### 4. Sync WaniKani Data

```bash
# Sync your vocabulary and kanji (this will take a few minutes)
docker compose exec web rails "wanikani:sync[1]"  # Replace 1 with your user ID

# Or reset and resync if you need to
docker compose exec web rails "wanikani:reset_and_resync[1]"
```

### 5. Generate Initial Dialogues

```bash
# Generate 10 beginner dialogues
docker compose exec web rails "dialogues:generate_now[1,10,beginner]"
```

### 6. Access the Application

Open your browser to [http://localhost:3000](http://localhost:3000)

**Available Pages:**
- `/` - Dashboard with stats and "Start Reading" button
- `/dialogues/new` - Generate more dialogues
- `/good_job` - Background job monitoring

## Development

### Running Commands

```bash
# Rails console
docker compose exec web rails console

# Run migrations
docker compose exec web rails db:migrate

# Run tests with RSpec
docker compose exec web bundle exec rspec

# Run linter
docker compose exec web bundle exec rubocop -A

# View logs
docker compose logs -f web
docker compose logs -f worker
```

### Services

- **Web**: Rails server on port 3000
- **Worker**: GoodJob background worker for scheduled syncs
- **DB**: PostgreSQL on port 5432

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes database data)
docker-compose down -v
```

## Project Structure

```
app/
├── controllers/
│   └── dialogues_controller.rb    # Main UI controller
├── models/
│   ├── user.rb                     # User with WaniKani/OpenRouter keys
│   ├── wani_subject.rb             # WaniKani vocabulary/kanji
│   ├── dialogue.rb                 # Generated dialogues
│   ├── comprehension_question.rb   # Questions for dialogues
│   └── dialogue_attempt.rb         # User progress tracking
├── jobs/
│   ├── wanikani_sync_job.rb        # Sync individual user
│   ├── wanikani_sync_all_users_job.rb  # Scheduled sync for all
│   └── generate_dialogues_job.rb   # Bulk dialogue generation
├── services/
│   ├── wanikani_client.rb          # WaniKani API wrapper
│   ├── wanikani_sync_service.rb    # Sync orchestration
│   ├── openrouter_client.rb        # OpenRouter AI wrapper
│   └── dialogue_generation_service.rb  # AI dialogue generation
└── views/
    └── dialogues/
        ├── index.html.erb          # Dashboard
        ├── show.html.erb           # Reading & questions
        ├── results.html.erb        # Score & review
        └── new.html.erb            # Generation form
```

## Background Jobs

This project uses GoodJob for background job processing with PostgreSQL.

### Monitoring Jobs

Access the GoodJob dashboard at: `http://localhost:3000/good_job`

### Scheduled Jobs

- **WaniKani Sync**: Runs every 6 hours to sync data for all users with configured API keys

### Manual Tasks

**WaniKani Sync:**
```bash
# Sync all users
docker compose exec web rails wanikani:sync_all

# Sync specific user
docker compose exec web rails "wanikani:sync[USER_ID]"

# Reset and resync (clears old data, resyncs based on current level)
docker compose exec web rails "wanikani:reset_and_resync[USER_ID]"
```

**Dialogue Generation:**
```bash
# Generate dialogues (async - queues job)
docker compose exec web rails "dialogues:generate[USER_ID,COUNT,DIFFICULTY]"

# Generate dialogues (sync - runs immediately)
docker compose exec web rails "dialogues:generate_now[USER_ID,10,beginner]"

# List dialogues for a user
docker compose exec web rails "dialogues:list[USER_ID]"
```

## Testing

This project uses RSpec for testing with FactoryBot for fixtures and SimpleCov for coverage.

```bash
# Run all specs
docker compose exec web bundle exec rspec

# Run specific spec file
docker compose exec web bundle exec rspec spec/models/user_spec.rb

# Run with coverage report (automatically generated)
docker compose exec web bundle exec rspec
# Coverage report available at: coverage/index.html

# Run linter
docker compose exec web bundle exec rubocop -A
```

**Current Test Stats:**
- 94 examples, 0 failures
- 65% code coverage
- ~3 second test suite

## How It Works

### 1. WaniKani Sync
- Fetches your current WaniKani level
- Syncs only vocabulary and kanji at or below your level
- Runs automatically every 6 hours
- Stores subjects in local database for fast access

### 2. Dialogue Generation
- Analyzes your vocabulary by difficulty level (beginner: 1-10, intermediate: 11-30, advanced: 31-60)
- Sends vocabulary list to OpenRouter AI (Claude 3.5 Sonnet)
- AI generates natural Japanese dialogue using ONLY your known words
- Creates 10 comprehension questions testing vocabulary, grammar, context, and inference
- Stores dialogue and questions in database

### 3. Reading Practice
- Dashboard shows random dialogue on each visit
- Read Japanese text, click "Ready?" to start questions
- Answer 4 randomly selected questions (out of 10 total)
- See immediate results with explanations
- Retry same dialogue with different random questions

### 4. Progress Tracking
- Tracks all attempts with scores
- Shows completion rate and average score
- Stores which questions were shown in each attempt
- Allows unlimited practice on any dialogue

## Key Design Decisions

- **Level-based sync**: Only syncs vocabulary you've learned to keep database lean
- **10 questions, 4 shown**: Allows multiple attempts on same dialogue with variety
- **Random dialogue selection**: Ensures varied practice
- **Dark mode**: Reduces eye strain during study sessions
- **Synchronous generation**: User sees progress and errors immediately
- **JSON sanitization**: Handles AI formatting variations gracefully

## Deployment

This application is Docker-ready and can be deployed to any container platform. The production Dockerfile is included for deployment with Kamal or similar tools.

**Environment Variables for Production:**
- `RAILS_ENV=production`
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Rails secret
- `WANIKANI_API_KEY` - For syncing (or per-user)
- `OPENROUTER_API_KEY` - For AI generation (or per-user)

## License

All rights reserved.
