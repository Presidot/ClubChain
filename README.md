# ClubChain

A decentralized social club member governance system for transparent club decision making on Stacks blockchain.

## Features

- Club measure proposal and management
- Member voting with membership-weighted decisions
- Representative assignment for member representation
- Seasonal governance cycles and timeline management
- Comprehensive club governance statistics

## Smart Contract Functions

### Public Functions
- `propose-measure` - Propose club measure for member voting (president only)
- `cast-member-vote` - Cast vote on measure with membership weight
- `assign-representative` - Assign representative for member representation
- `close-measure` - Close measure voting (president only)
- `advance-season` - Advance seasonal cycle (president only)

### Read-Only Functions
- `get-measure-membership-total` - Get total membership voted on measure
- `get-member-membership-level` - Get member's membership level
- `get-measure-status` - Check if measure voting is active
- `get-current-season` - Get current season
- `get-club-stats` - Get comprehensive club statistics

## Governance Features
- Membership-weighted voting system
- Representative mechanism
- Seasonal decision cycles
- President authorization controls

## Usage

Deploy the contract to create a social club governance system where members can vote on measures, assign representatives, and participate in democratic club decision making.

## License

MIT