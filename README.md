# Nekodesu - Japanese Language Learning Tool

A Rails application that helps users learn Japanese by generating contextual dialogues based on their current WaniKani and Marumori vocabulary knowledge.

## Features

- **API Integration**: Syncs your learned kanji and vocabulary from WaniKani and Marumori
- **AI-Powered Learning**: Generates custom Japanese dialogues using OpenRouter AI based on your knowledge level
- **Comprehension Testing**: Multiple choice questions to test your understanding
- **Background Jobs**: Periodic scheduled syncs using GoodJob with PostgreSQL backend

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
- API Keys for:
  - [WaniKani](https://www.wanikani.com/settings/personal_access_tokens)
  - Marumori
  - [OpenRouter](https://openrouter.ai/keys)

## Getting Started

### 1. Clone and Setup Environment

```bash
# Copy the example environment file
cp env.example .env

# Edit .env and add your API keys
# WANIKANI_API_KEY=your_key_here
# MARUMORI_API_KEY=your_key_here
# OPENROUTER_API_KEY=your_key_here
```

### 2. Build and Start Services

```bash
# Build the Docker images
docker-compose build

# Start all services (web, worker, database)
docker-compose up
```

### 3. Setup Database

```bash
# Create and migrate the database
docker-compose exec web rails db:create db:migrate

# (Optional) Load seed data
docker-compose exec web rails db:seed
```

### 4. Access the Application

Open your browser to [http://localhost:3000](http://localhost:3000)

## Development

### Running Commands

```bash
# Rails console
docker-compose exec web rails console

# Run migrations
docker-compose exec web rails db:migrate

# Run tests
docker-compose exec web rails test

# Generate a model
docker-compose exec web rails generate model ModelName

# View logs
docker-compose logs -f web
docker-compose logs -f worker
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
├── controllers/     # Request handlers
├── models/          # Data models (User, KanjiItem, VocabularyItem, etc.)
├── jobs/            # Background jobs (WaniKani sync, Marumori sync)
├── services/        # Business logic (API clients, AI dialogue generation)
└── views/           # ERB templates

config/
├── database.yml     # Database configuration
└── routes.rb        # URL routing

db/
├── migrate/         # Database migrations
└── seeds.rb         # Seed data
```

## Testing

This project uses RSpec for testing with FactoryBot for fixtures and SimpleCov for coverage.

```bash
# Run all specs
docker compose exec web bundle exec rspec

# Run specific spec file
docker compose exec web bundle exec rspec spec/models/user_spec.rb

# Run with coverage report
docker compose exec web bundle exec rspec

# Run specs matching a pattern
docker compose exec web bundle exec rspec --tag focus
```

## Deployment

This application is Docker-ready and can be deployed to any container platform. The production Dockerfile is included for deployment with Kamal or similar tools.

## License

All rights reserved.
