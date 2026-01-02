# 猫です (Nekodesu) - Japanese Reading Comprehension Practice

A Rails application that generates personalized Japanese dialogues based on your WaniKani and Renshuu vocabulary. Practice reading comprehension with AI-generated content tailored to your current knowledge from both study platforms.

## Features

### 🎯 Core Features
- **Triple Vocabulary Sources**:
  - **WaniKani Integration**: Syncs vocabulary and kanji at or below your current level
  - **Renshuu Integration**: Syncs your studied vocabulary, kanji, grammar points, and sentences
  - **Anki Integration**: Import your Anki flashcard decks (.apkg files) to include your custom vocabulary
  - **Smart Combination**: Creates non-redundant superset from all three sources
- **AI-Powered Dialogues**: Generates natural Japanese conversations using OpenRouter AI (Claude 3.5 Sonnet)
- **Text-to-Speech Audio**:
  - **OpenAI TTS Integration**: Generates natural-sounding audio for each dialogue line
  - **Character Voices**: Each character has a unique voice (echo, onyx, nova, fable)
  - **Audio Listening Mode**: Listen to dialogues with custom audio controls
  - **Background Processing**: Audio generation happens asynchronously via background jobs
- **Random Vocabulary Sampling**: Each dialogue uses a different random selection from your combined vocabulary pool
- **Smart Question System**: 10 comprehension questions per dialogue, 4 randomly selected per attempt
- **Progress Tracking**: Track your scores, completion rate, and improvement over time
- **Retry System**: Practice the same dialogue multiple times with different random questions

### 🎨 User Experience
- **Dual Practice Modes**:
  - **Reading Mode**: Text-based dialogue with comprehension questions
  - **Listening Mode**: Audio-first experience with text reveal on click
- **Interactive Audio Controls**:
  - Custom play/pause buttons for each dialogue line
  - "Play All" feature for sequential playback
  - Visual feedback with play/pause icon transitions
- **Text Reveal System**: Text obscured by default, click to reveal (maintains selectability)
- **Dark Mode**: Full dark mode support with persistent preference
- **Responsive Design**: Beautiful Tailwind CSS interface that works on all devices
- **Real-time Generation**: Generate new dialogues on-demand through the UI
- **Difficulty Levels**: Beginner (N5), Intermediate (N4-N3), Advanced (N2-N1)

### ⚙️ Technical Features
- **Background Jobs**:
  - Scheduled syncs (every 6 hours, offset) for both WaniKani and Renshuu
  - Async audio generation with retry logic (3 attempts with exponential backoff)
- **Active Storage**: MP3 audio files stored with metadata in JSONB
- **Level-Based Content**: WaniKani vocabulary filtered by level, Renshuu uses all studied items
- **Smart Sampling**: Randomly selects up to 200 kanji + 300 vocabulary per dialogue from combined pool
- **Grammar Matching**: Dialogue complexity matches JLPT level expectations
- **Robust Parsing**: Handles AI response variations and formatting issues

## Tech Stack

- **Framework**: Rails 8.1
- **Database**: PostgreSQL 16
- **Job Processing**: GoodJob (PostgreSQL-backed)
- **File Storage**: Active Storage (for audio files)
- **Views**: ERB with Tailwind CSS
- **HTTP Client**: Faraday
- **AI Integrations**:
  - OpenRouter gem (Claude 3.5 Sonnet for dialogue generation)
  - OpenAI TTS API (text-to-speech audio generation)
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker and Docker Compose
- API Keys:
  - [WaniKani API Key](https://www.wanikani.com/settings/personal_access_tokens) - Required for WaniKani vocabulary sync
  - [Renshuu API Key](https://www.renshuu.org/index.php?page=profile/api) - Required for Renshuu vocabulary sync
  - [OpenRouter API Key](https://openrouter.ai/keys) - Required for AI dialogue generation
  - [OpenAI API Key](https://platform.openai.com/api-keys) - Required for text-to-speech audio generation

## Getting Started

### 1. Build and Start Services

```bash
# Build the Docker images
docker compose build

# Start all services (web, worker, database)
docker compose up -d
```

### 2. Setup Database

```bash
# Create and migrate the database
docker compose exec web rails db:create db:migrate

# Create a user (in Rails console)
docker compose exec web rails console
# > User.create!(email: "your@email.com")
```

### 3. Configure API Keys

Open your browser to [http://localhost:3000/settings](http://localhost:3000/settings)

Configure your API keys through the Settings UI:
- **WaniKani API Key** - Get from [WaniKani Settings](https://www.wanikani.com/settings/personal_access_tokens)
- **Renshuu API Key** - Get from [Renshuu API Settings](https://www.renshuu.org/index.php?page=profile/api)
- **OpenRouter API Key** - Get from [OpenRouter Keys](https://openrouter.ai/keys)
- **OpenAI API Key** - Get from [OpenAI API Keys](https://platform.openai.com/api-keys)
- **Speech Speed** - Adjust TTS audio speed (0.25 to 4.0, default 1.0)

### 4. Import Vocabulary (Optional)

**Import Anki Decks:**
- Go to Settings and upload your `.apkg` files
- Only well-known cards (21+ day intervals) are used in dialogues

**Sync WaniKani & Renshuu:**
```bash
# Sync WaniKani vocabulary and kanji (this will take a few minutes)
docker compose exec web rails "wanikani:sync[1]"  # Replace 1 with your user ID

# Sync Renshuu vocabulary, kanji, and grammar
docker compose exec web rails "renshuu:sync[1]"  # Replace 1 with your user ID

# Or reset and resync if you need to
docker compose exec web rails "wanikani:reset_and_resync[1]"
docker compose exec web rails "renshuu:reset_and_resync[1]"
```

### 5. Generate Dialogues

Use the web UI at [http://localhost:3000/dialogues/new](http://localhost:3000/dialogues/new) or via command line:

```bash
# Generate 10 beginner dialogues
docker compose exec web rails "dialogues:generate_now[1,10,beginner]"
```

### 6. Access the Application

Open your browser to [http://localhost:3000](http://localhost:3000)

**Available Pages:**
- `/` - Dashboard with stats, "Start Reading" and "Start Listening" buttons
- `/settings` - Configure API keys, import Anki decks, adjust audio settings
- `/dialogues/new` - Generate more dialogues
- `/dialogues/:id/listen` - Audio listening mode with text reveal
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
│   ├── generate_dialogues_job.rb   # Bulk dialogue generation
│   └── generate_dialogue_audio_job.rb  # Async audio generation
├── services/
│   ├── wanikani_client.rb          # WaniKani API wrapper
│   ├── wanikani_sync_service.rb    # Sync orchestration
│   ├── openrouter_client.rb        # OpenRouter AI wrapper
│   ├── openai_tts_client.rb        # OpenAI TTS API wrapper
│   ├── dialogue_generation_service.rb  # AI dialogue generation
│   └── dialogue_audio_generation_service.rb  # Audio generation orchestration
└── views/
    └── dialogues/
        ├── index.html.erb          # Dashboard
        ├── show.html.erb           # Reading & questions
        ├── listen.html.erb         # Audio listening mode
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


## How It Works

### 1. Vocabulary Sync
**WaniKani:**
- Fetches your current WaniKani level
- Syncs only vocabulary and kanji at or below your level
- Runs automatically every 6 hours (at :00)
- Stores subjects in local database for fast access

**Renshuu:**
- Fetches all your studied vocabulary, kanji, grammar, and sentences
- No level filtering - uses everything you've studied
- Runs automatically every 6 hours (at :03, offset from WaniKani)
- Stores items in local database

**Anki:**
- Import your Anki flashcard decks (.apkg files) via the web UI
- Extracts Japanese vocabulary from card fields
- Preserves review statistics (intervals, lapses, review counts)
- Only well-known cards (21+ day intervals) are used in dialogue generation
- Supports re-importing to update existing cards
- Manual import only (no automatic sync)

### 2. Dialogue Generation
- **Random Sampling**: Selects up to 150 kanji + 200 vocab from WaniKani, Renshuu, and Anki
- **Combines & Deduplicates**: Creates non-redundant superset from all three sources
- **Final Selection**: Randomly picks up to 200 kanji + 300 vocab for the AI prompt
- **AI Generation**: Sends combined vocabulary to OpenRouter AI (Claude 3.5 Sonnet)
- AI generates natural Japanese dialogue using ONLY the provided words
- Creates 10 comprehension questions testing vocabulary, grammar, context, and inference
- Stores dialogue and questions in database
- **Each dialogue is unique** due to random vocabulary selection

### 3. Audio Generation
- After dialogue creation, audio generation job is automatically queued
- Background job processes each dialogue line with OpenAI TTS
- Each character gets a unique voice (田中さん: echo, 山田くん: onyx, ゆみちゃん: nova, 小川先生: fable)
- Audio files stored in Active Storage with metadata in JSONB
- Retry logic handles API failures (3 attempts with exponential backoff)

### 4. Reading Practice
- Dashboard shows random dialogue on each visit
- **Reading Mode**: Read Japanese text, click "Ready?" to start questions
- **Listening Mode**: Listen to audio with text obscured, click bubbles to reveal
- Answer 4 randomly selected questions (out of 10 total)
- See immediate results with explanations
- Retry same dialogue with different random questions

### 5. Progress Tracking
- Tracks all attempts with scores
- Shows completion rate and average score
- Stores which questions were shown in each attempt
- Allows unlimited practice on any dialogue

## Key Design Decisions

- **Triple vocabulary sources**: Combines WaniKani (level-based) + Renshuu (all studied items) + Anki (well-known cards) for maximum coverage
- **Smart sampling**: Random selection from combined pool ensures variety while respecting token limits
- **Non-redundant superset**: Deduplicates overlapping items between sources
- **Anki mastery filtering**: Only uses Anki cards with 21+ day intervals to ensure vocabulary is well-known
- **Character-specific voices**: Each character has a unique TTS voice for natural conversation feel
- **Async audio generation**: Background processing prevents UI blocking, with retry logic for reliability
- **Text reveal with selectability**: Overlay approach obscures text while maintaining copy/paste functionality
- **Custom audio controls**: Circular play/pause buttons with sequential "Play All" feature
- **10 questions, 4 shown**: Allows multiple attempts on same dialogue with variety
- **Random dialogue selection**: Ensures varied practice
- **Dark mode**: Reduces eye strain during study sessions
- **Synchronous generation**: User sees progress and errors immediately
- **JSON sanitization**: Handles AI formatting variations gracefully
- **Offset sync schedules**: WaniKani and Renshuu syncs run at different times to distribute load

## Deployment

This application is Docker-ready and includes a complete production deployment setup with GitHub Actions CI/CD.

**📚 [Full Deployment Guide](docs/DEPLOYMENT.md)**

### Quick Start

For deployment to Hetzner VPC with Cloudflare Tunnel:

```bash
# On your Hetzner server
bash <(curl -fsSL https://raw.githubusercontent.com/matthewlawrenceklein/nekodesu/main/script/server-setup.sh)

# Configure environment
nano /opt/nekodesu/.env.production

# Setup Cloudflare Tunnel
cd /opt/nekodesu && ./script/setup-cloudflare-tunnel.sh

# Deploy
cd /opt/nekodesu && ./script/deploy.sh
```

**Automated Deployments:**
- Push to `main` branch triggers automatic deployment via GitHub Actions
- Includes tests, Docker image build, and zero-downtime deployment

**API Key Configuration:**
All API keys are configured per-user through the Settings UI (`/settings`):
- WaniKani API Key - Required for vocabulary sync
- Renshuu API Key - Required for Renshuu integration
- OpenRouter API Key - Required for dialogue generation
- OpenAI API Key - Required for audio generation

## License

All rights reserved.
