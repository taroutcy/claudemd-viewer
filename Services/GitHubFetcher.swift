import Foundation

/// GitHub API通信サービス
/// CLAUDE.mdをGitHub Raw Content APIから取得
class GitHubFetcher {

    // MARK: - Error Types

    enum FetchError: Error, LocalizedError {
        case notFound
        case invalidUrl
        case networkError(Error)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "CLAUDE.md not found in this repo"
            case .invalidUrl:
                return "Invalid GitHub URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from GitHub"
            }
        }
    }

    // MARK: - Rate Limit Info

    struct RateLimitInfo {
        let limit: Int
        let remaining: Int
        let reset: Date?

        init(limit: Int = 60, remaining: Int = 60, reset: Date? = nil) {
            self.limit = limit
            self.remaining = remaining
            self.reset = reset
        }
    }

    private(set) var rateLimitInfo = RateLimitInfo()

    // MARK: - Public Methods

    /// GitHub URLからowner/repoを抽出
    /// - Parameter input: GitHub URL (例: "https://github.com/vercel/next.js")
    /// - Returns: (owner, repo)のタプル。解析できない場合はnil
    func parseGitHubUrl(_ input: String) -> (owner: String, repo: String)? {
        // URLから不要な部分を削除してクリーンアップ
        let cleaned = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: "http://github.com/", with: "")
            .replacingOccurrences(of: "www.github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // "/" で分割してowner/repoを取得
        let parts = cleaned.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }

        // owner と repo を返す（それ以降のパスは無視）
        return (owner: parts[0], repo: parts[1])
    }

    /// GitHub リポジトリから CLAUDE.md を取得
    /// main ブランチを試し、404 なら master ブランチでリトライ
    /// - Parameters:
    ///   - owner: リポジトリオーナー
    ///   - repo: リポジトリ名
    /// - Returns: CLAUDE.md の内容
    /// - Throws: FetchError
    func fetchClaudeMd(owner: String, repo: String) async throws -> String {
        let branches = ["main", "master"]

        for branch in branches {
            let urlString = "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/CLAUDE.md"
            guard let url = URL(string: urlString) else {
                throw FetchError.invalidUrl
            }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                // レート制限ヘッダーをパース
                if let httpResponse = response as? HTTPURLResponse {
                    parseRateLimitHeaders(httpResponse)

                    if httpResponse.statusCode == 200 {
                        guard let content = String(data: data, encoding: .utf8) else {
                            throw FetchError.invalidResponse
                        }
                        return content
                    } else if httpResponse.statusCode == 404 {
                        // 404 の場合は次のブランチを試す
                        continue
                    } else {
                        throw FetchError.invalidResponse
                    }
                }
            } catch let error as FetchError {
                throw error
            } catch {
                // 最後のブランチでエラーが発生した場合のみスロー
                if branch == branches.last {
                    throw FetchError.networkError(error)
                }
                // それ以外は次のブランチを試す
                continue
            }
        }

        // すべてのブランチで見つからなかった
        throw FetchError.notFound
    }

    /// GitHub リポジトリの情報を取得（スター数など）
    /// - Parameters:
    ///   - owner: リポジトリオーナー
    ///   - repo: リポジトリ名
    /// - Returns: スター数の文字列（例: "1.2k", "92.5k"）
    /// - Throws: FetchError
    func fetchRepoInfo(owner: String, repo: String) async throws -> String {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)"
        guard let url = URL(string: urlString) else {
            throw FetchError.invalidUrl
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // レート制限ヘッダーをパース
            if let httpResponse = response as? HTTPURLResponse {
                parseRateLimitHeaders(httpResponse)

                guard httpResponse.statusCode == 200 else {
                    throw FetchError.invalidResponse
                }
            }

            // JSON をパース
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let stargazersCount = json["stargazers_count"] as? Int {
                return formatStarCount(stargazersCount)
            }

            return "0"
        } catch let error as FetchError {
            throw error
        } catch {
            throw FetchError.networkError(error)
        }
    }

    // MARK: - Private Methods

    /// HTTPレスポンスヘッダーからレート制限情報をパース
    /// - Parameter response: HTTPURLResponse
    private func parseRateLimitHeaders(_ response: HTTPURLResponse) {
        let headers = response.allHeaderFields

        let limit = (headers["X-RateLimit-Limit"] as? String).flatMap { Int($0) } ?? 60
        let remaining = (headers["X-RateLimit-Remaining"] as? String).flatMap { Int($0) } ?? 60
        let resetTimestamp = (headers["X-RateLimit-Reset"] as? String).flatMap { Double($0) }
        let reset = resetTimestamp.map { Date(timeIntervalSince1970: $0) }

        rateLimitInfo = RateLimitInfo(limit: limit, remaining: remaining, reset: reset)
    }

    /// スター数を人間に読みやすい形式にフォーマット
    /// - Parameter count: スター数
    /// - Returns: フォーマット済みの文字列（例: "1.2k", "92.5k", "1.5m"）
    private func formatStarCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<10000:
            let k = Double(count) / 1000.0
            return String(format: "%.1fk", k)
        case 10000..<1_000_000:
            let k = Double(count) / 1000.0
            return String(format: "%.1fk", k)
        case 1_000_000...:
            let m = Double(count) / 1_000_000.0
            return String(format: "%.1fm", m)
        default:
            return "\(count)"
        }
    }
}
