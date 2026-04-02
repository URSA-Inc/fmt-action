# FMT Equivalence Checker

Prove functional equivalence between two functions using formal methods, directly in your CI pipeline.

## Usage

```yaml
- uses: URSA-Inc/fmt-action@v1
  with:
    api_key: ${{ secrets.FMT_API_KEY }}
    function_a: |
      def calculate_total(items):
          return sum(item.price for item in items)
    function_b: |
      def calculate_total(items):
          total = 0
          for item in items:
              total += item.price
          return total
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `api_key` | Yes | — | FMT API key (store as a GitHub secret) |
| `function_a` | Yes | — | First function source code |
| `function_b` | Yes | — | Second function to compare against |
| `language` | No | `python` | Programming language |
| `timeout` | No | `30` | Proof timeout in seconds |
| `api_url` | No | `https://api.fmt.ursasecure.com` | API base URL |

## Outputs

| Output | Description |
|--------|-------------|
| `job_id` | The equivalence check job ID |
| `equivalent` | `true`, `false`, or `unknown` |
| `status` | `complete` or `failed` |

## Getting an API key

Visit [fmt.ursasecure.com](https://fmt.ursasecure.com) to sign up for access.
