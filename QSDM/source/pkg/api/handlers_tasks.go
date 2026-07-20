package api

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strings"

	"github.com/blackbeardONE/QSD/pkg/chain"
)

const QSDTaskRegistryPathEnv = "QSD_TASK_REGISTRY_PATH"

const QSDTaskDefaultPublicKey = "11111111111111111111111111111111"

const QSDTaskRegistrySource = "operator-registry"

type QSDTaskSubmission struct {
	SubmissionValue string  `json:"submission_value"`
	Slot            uint64  `json:"slot"`
	RewardAmount    float64 `json:"reward_amount,omitempty"`
	Claimed         bool    `json:"claimed,omitempty"`
	ClaimedAt       string  `json:"claimed_at,omitempty"`
}

type QSDTask struct {
	TaskID                        string                                   `json:"task_id"`
	TaskName                      string                                   `json:"task_name"`
	TaskManager                   string                                   `json:"task_manager"`
	IsAllowlisted                 bool                                     `json:"is_allowlisted"`
	IsActive                      bool                                     `json:"is_active"`
	TaskAuditProgram              string                                   `json:"task_audit_program"`
	StakePotAccount               string                                   `json:"stake_pot_account"`
	TotalBountyAmount             float64                                  `json:"total_bounty_amount"`
	BountyAmountPerRound          float64                                  `json:"bounty_amount_per_round"`
	CurrentRound                  uint64                                   `json:"current_round"`
	AvailableBalances             map[string]float64                       `json:"available_balances"`
	StakeList                     map[string]float64                       `json:"stake_list"`
	TaskMetadata                  string                                   `json:"task_metadata"`
	TaskDescription               string                                   `json:"task_description"`
	Submissions                   map[string]map[string]QSDTaskSubmission `json:"submissions"`
	SubmissionsAuditTrigger       map[string]map[string]interface{}        `json:"submissions_audit_trigger"`
	TotalStakeAmount              float64                                  `json:"total_stake_amount"`
	RewardPoolAmount              float64                                  `json:"reward_pool_amount,omitempty"`
	PendingRewardAmount           float64                                  `json:"pending_reward_amount,omitempty"`
	TotalRewardPaidAmount         float64                                  `json:"total_reward_paid_amount,omitempty"`
	MinimumStakeAmount            float64                                  `json:"minimum_stake_amount"`
	IPAddressList                 map[string]string                        `json:"ip_address_list"`
	RoundTime                     uint64                                   `json:"round_time"`
	StartingSlot                  uint64                                   `json:"starting_slot"`
	AuditWindow                   uint64                                   `json:"audit_window"`
	SubmissionWindow              uint64                                   `json:"submission_window"`
	TaskExecutableNetwork         string                                   `json:"task_executable_network"`
	DistributionRewardsSubmission map[string]map[string]QSDTaskSubmission `json:"distribution_rewards_submission"`
	DistributionsAuditTrigger     map[string]map[string]interface{}        `json:"distributions_audit_trigger"`
	DistributionsAuditRecord      map[string]string                        `json:"distributions_audit_record"`
	TaskVars                      string                                   `json:"task_vars"`
	KoiiVars                      string                                   `json:"koii_vars"`
	IsMigrated                    bool                                     `json:"is_migrated"`
	MigratedTo                    string                                   `json:"migrated_to"`
	AllowedFailedDistributions    uint64                                   `json:"allowed_failed_distributions"`
	TaskType                      string                                   `json:"task_type,omitempty"`
	TokenType                     string                                   `json:"token_type,omitempty"`
	NativeRuntime                 string                                   `json:"native_runtime,omitempty"`
	Manifest                      *chain.TaskManifest                      `json:"manifest,omitempty"`
	CatalogVersion                uint64                                   `json:"catalog_version,omitempty"`
	CatalogPaused                 bool                                     `json:"catalog_paused,omitempty"`
	CatalogPublishedAt            string                                   `json:"catalog_published_at,omitempty"`
	CatalogUpdatedAt              string                                   `json:"catalog_updated_at,omitempty"`
}

type QSDTaskRegistryFile struct {
	Tasks []QSDTask `json:"tasks"`
}

type QSDTasksListResponse struct {
	Runtime          string     `json:"runtime"`
	Configured       bool       `json:"configured"`
	Source           string     `json:"source,omitempty"`
	CatalogSource    string     `json:"catalog_source,omitempty"`
	CatalogStateRoot string     `json:"catalog_state_root,omitempty"`
	Tasks            []QSDTask `json:"tasks"`
}

type QSDTaskResponse struct {
	Runtime          string   `json:"runtime"`
	Configured       bool     `json:"configured"`
	Source           string   `json:"source,omitempty"`
	CatalogSource    string   `json:"catalog_source,omitempty"`
	CatalogStateRoot string   `json:"catalog_state_root,omitempty"`
	Task             QSDTask `json:"task"`
}

type QSDTaskSubmissionsResponse struct {
	Runtime     string                                   `json:"runtime"`
	Configured  bool                                     `json:"configured"`
	TaskID      string                                   `json:"task_id"`
	Submissions map[string]map[string]QSDTaskSubmission `json:"submissions"`
}

type QSDTaskCatalogFingerprintRecord struct {
	TaskID                     string              `json:"task_id"`
	TaskName                   string              `json:"task_name"`
	TaskManager                string              `json:"task_manager"`
	IsAllowlisted              bool                `json:"is_allowlisted"`
	IsActive                   bool                `json:"is_active"`
	TaskAuditProgram           string              `json:"task_audit_program"`
	StakePotAccount            string              `json:"stake_pot_account"`
	TotalBountyAmount          float64             `json:"total_bounty_amount"`
	BountyAmountPerRound       float64             `json:"bounty_amount_per_round"`
	MinimumStakeAmount         float64             `json:"minimum_stake_amount"`
	TaskMetadata               string              `json:"task_metadata"`
	TaskDescription            string              `json:"task_description"`
	RoundTime                  uint64              `json:"round_time"`
	StartingSlot               uint64              `json:"starting_slot"`
	AuditWindow                uint64              `json:"audit_window"`
	SubmissionWindow           uint64              `json:"submission_window"`
	TaskExecutableNetwork      string              `json:"task_executable_network"`
	TaskVars                   string              `json:"task_vars"`
	TaskType                   string              `json:"task_type"`
	TokenType                  string              `json:"token_type"`
	NativeRuntime              string              `json:"native_runtime"`
	AllowedFailedDistributions uint64              `json:"allowed_failed_distributions"`
	Manifest                   *chain.TaskManifest `json:"manifest,omitempty"`
	CatalogVersion             uint64              `json:"catalog_version,omitempty"`
	CatalogPaused              bool                `json:"catalog_paused,omitempty"`
	CatalogPublishedAt         string              `json:"catalog_published_at,omitempty"`
	CatalogUpdatedAt           string              `json:"catalog_updated_at,omitempty"`
}

// QSDTaskCatalogFingerprint hashes only task definitions and compatibility
// metadata. Live stake, rewards, submissions, and round counters are excluded,
// so the fingerprint changes only when the effective catalog changes.
func QSDTaskCatalogFingerprint(tasks []QSDTask) string {
	records := make([]QSDTaskCatalogFingerprintRecord, 0, len(tasks))
	for _, task := range tasks {
		records = append(records, QSDTaskCatalogFingerprintRecord{
			TaskID:                     task.TaskID,
			TaskName:                   task.TaskName,
			TaskManager:                task.TaskManager,
			IsAllowlisted:              task.IsAllowlisted,
			IsActive:                   task.IsActive,
			TaskAuditProgram:           task.TaskAuditProgram,
			StakePotAccount:            task.StakePotAccount,
			TotalBountyAmount:          task.TotalBountyAmount,
			BountyAmountPerRound:       task.BountyAmountPerRound,
			MinimumStakeAmount:         task.MinimumStakeAmount,
			TaskMetadata:               task.TaskMetadata,
			TaskDescription:            task.TaskDescription,
			RoundTime:                  task.RoundTime,
			StartingSlot:               task.StartingSlot,
			AuditWindow:                task.AuditWindow,
			SubmissionWindow:           task.SubmissionWindow,
			TaskExecutableNetwork:      task.TaskExecutableNetwork,
			TaskVars:                   task.TaskVars,
			TaskType:                   task.TaskType,
			TokenType:                  task.TokenType,
			NativeRuntime:              task.NativeRuntime,
			AllowedFailedDistributions: task.AllowedFailedDistributions,
			Manifest:                   task.Manifest,
			CatalogVersion:             task.CatalogVersion,
			CatalogPaused:              task.CatalogPaused,
			CatalogPublishedAt:         task.CatalogPublishedAt,
			CatalogUpdatedAt:           task.CatalogUpdatedAt,
		})
	}
	sort.Slice(records, func(i, j int) bool {
		return records[i].TaskID < records[j].TaskID
	})
	raw, err := json.Marshal(records)
	if err != nil {
		return ""
	}
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func loadQSDTasksFromRegistry() (QSDTasksListResponse, error) {
	path := strings.TrimSpace(os.Getenv(QSDTaskRegistryPathEnv))
	if path == "" {
		return QSDTasksListResponse{
			Runtime:    "QSD-native",
			Configured: false,
			Tasks:      []QSDTask{},
		}, nil
	}

	raw, err := os.ReadFile(path) // #nosec G304,G703 -- path is selected from trusted startup configuration, never the request.
	if err != nil {
		return QSDTasksListResponse{}, err
	}
	// Windows PowerShell 5.1 writes UTF-8 with a BOM by default. Accept an
	// existing BOM so an otherwise valid operator registry cannot take the
	// public task catalog offline.
	raw = bytes.TrimPrefix(raw, []byte{0xEF, 0xBB, 0xBF})

	var wrapped QSDTaskRegistryFile
	if err := json.Unmarshal(raw, &wrapped); err != nil || wrapped.Tasks == nil {
		var tasks []QSDTask
		if arrayErr := json.Unmarshal(raw, &tasks); arrayErr != nil {
			if err != nil {
				return QSDTasksListResponse{}, err
			}
			return QSDTasksListResponse{}, arrayErr
		}
		wrapped.Tasks = tasks
	}

	tasks := make([]QSDTask, 0, len(wrapped.Tasks))
	for _, task := range wrapped.Tasks {
		task = normalizeQSDTask(task)
		if task.TaskID != "" {
			tasks = append(tasks, task)
		}
	}

	return QSDTasksListResponse{
		Runtime:    "QSD-native",
		Configured: true,
		Source:     QSDTaskRegistrySource,
		Tasks:      tasks,
	}, nil
}

func normalizeQSDTask(task QSDTask) QSDTask {
	task.TaskID = strings.TrimSpace(task.TaskID)
	task.TaskName = strings.TrimSpace(task.TaskName)
	if task.TaskName == "" {
		task.TaskName = task.TaskID
	}
	if strings.TrimSpace(task.TaskManager) == "" {
		task.TaskManager = QSDTaskDefaultPublicKey
	}
	if strings.TrimSpace(task.StakePotAccount) == "" {
		task.StakePotAccount = QSDTaskDefaultPublicKey
	}
	if strings.TrimSpace(task.TaskAuditProgram) == "" {
		task.TaskAuditProgram = task.TaskID
	}
	if strings.TrimSpace(task.TaskMetadata) == "" {
		task.TaskMetadata = task.TaskID
	}
	if strings.TrimSpace(task.TaskExecutableNetwork) == "" {
		task.TaskExecutableNetwork = "IPFS"
	}
	if strings.TrimSpace(task.TaskVars) == "" {
		task.TaskVars = "{}"
	}
	if strings.TrimSpace(task.KoiiVars) == "" {
		task.KoiiVars = "{}"
	}
	if strings.EqualFold(strings.TrimSpace(task.TaskType), "KPL") ||
		strings.TrimSpace(task.TokenType) != "" {
		task.TaskType = "KPL"
	} else {
		// Early QSD registries used KOII for native tasks. Catalog consumers
		// must receive the actual native denomination so CELL balances are used.
		task.TaskType = "CELL"
	}
	task.NativeRuntime = "QSD"

	if task.AvailableBalances == nil {
		task.AvailableBalances = map[string]float64{}
	}
	if task.StakeList == nil {
		task.StakeList = map[string]float64{}
	}
	if task.IPAddressList == nil {
		task.IPAddressList = map[string]string{}
	}
	if task.Submissions == nil {
		task.Submissions = map[string]map[string]QSDTaskSubmission{}
	}
	if task.SubmissionsAuditTrigger == nil {
		task.SubmissionsAuditTrigger = map[string]map[string]interface{}{}
	}
	if task.DistributionRewardsSubmission == nil {
		task.DistributionRewardsSubmission = map[string]map[string]QSDTaskSubmission{}
	}
	if task.DistributionsAuditTrigger == nil {
		task.DistributionsAuditTrigger = map[string]map[string]interface{}{}
	}
	if task.DistributionsAuditRecord == nil {
		task.DistributionsAuditRecord = map[string]string{}
	}
	return task
}

func findQSDTask(tasks []QSDTask, taskID string) (QSDTask, bool) {
	for _, task := range tasks {
		if task.TaskID == taskID {
			return task, true
		}
	}
	return QSDTask{}, false
}

func (h *Handlers) QSDTasksListHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.Header().Set("Allow", http.MethodGet)
		writeErrorResponse(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	response, err := loadQSDTasksFromRegistry()
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "failed to load QSD task registry: "+err.Error())
		return
	}
	projection, err := applyQSDTaskActionProjection(response.Tasks)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "failed to project QSD task state: "+err.Error())
		return
	}
	response.Tasks = projection.Tasks
	response.Configured = response.Configured || projection.Configured
	response.CatalogSource = projection.Source
	response.CatalogStateRoot = QSDTaskCatalogFingerprint(response.Tasks)

	writeJSONResponse(w, http.StatusOK, response)
}

func (h *Handlers) QSDTaskRouteHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.Header().Set("Allow", http.MethodGet)
		writeErrorResponse(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/v1/tasks/")
	if path == "" {
		writeErrorResponse(w, http.StatusBadRequest, "task_id required")
		return
	}

	wantsSubmissions := strings.HasSuffix(path, "/submissions")
	if wantsSubmissions {
		path = strings.TrimSuffix(path, "/submissions")
	}
	wantsState := strings.HasSuffix(path, "/state")
	if wantsState {
		path = strings.TrimSuffix(path, "/state")
	}
	taskID, err := url.PathUnescape(strings.Trim(path, "/"))
	if err != nil || strings.TrimSpace(taskID) == "" {
		writeErrorResponse(w, http.StatusBadRequest, "invalid task_id")
		return
	}

	registry, err := loadQSDTasksFromRegistry()
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "failed to load QSD task registry: "+err.Error())
		return
	}
	projection, err := applyQSDTaskActionProjection(registry.Tasks)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "failed to project QSD task state: "+err.Error())
		return
	}
	registry.Tasks = projection.Tasks
	registry.Configured = registry.Configured || projection.Configured
	registry.CatalogSource = projection.Source
	registry.CatalogStateRoot = QSDTaskCatalogFingerprint(registry.Tasks)

	task, ok := findQSDTask(registry.Tasks, taskID)
	if !ok {
		if wantsState {
			store, path, configured, err := loadQSDTaskActionStateStore()
			if err != nil {
				writeErrorResponse(w, http.StatusInternalServerError, "failed to project QSD task state: "+err.Error())
				return
			}
			state, stateOK := store.GetTask(taskID)
			if stateOK {
				writeJSONResponse(w, http.StatusOK, QSDTaskStateResponse{
					Runtime:    registry.Runtime,
					Configured: configured,
					Source:     path,
					StateRoot:  store.StateRoot(),
					Task:       state,
				})
				return
			}
		}
		writeErrorResponse(w, http.StatusNotFound, "task not found")
		return
	}

	if wantsSubmissions {
		writeJSONResponse(w, http.StatusOK, QSDTaskSubmissionsResponse{
			Runtime:     registry.Runtime,
			Configured:  registry.Configured,
			TaskID:      task.TaskID,
			Submissions: task.Submissions,
		})
		return
	}
	if wantsState {
		store, path, configured, err := loadQSDTaskActionStateStore()
		if err != nil {
			writeErrorResponse(w, http.StatusInternalServerError, "failed to project QSD task state: "+err.Error())
			return
		}
		state, ok := store.GetTask(task.TaskID)
		if !ok {
			state = chain.TaskState{
				TaskID:       task.TaskID,
				Participants: map[string]chain.TaskParticipantState{},
				Submissions:  map[string]map[string]chain.TaskSubmissionState{},
			}
		}
		writeJSONResponse(w, http.StatusOK, QSDTaskStateResponse{
			Runtime:    registry.Runtime,
			Configured: configured,
			Source:     path,
			StateRoot:  store.StateRoot(),
			Task:       state,
		})
		return
	}

	writeJSONResponse(w, http.StatusOK, QSDTaskResponse{
		Runtime:          registry.Runtime,
		Configured:       registry.Configured,
		Source:           registry.Source,
		CatalogSource:    registry.CatalogSource,
		CatalogStateRoot: registry.CatalogStateRoot,
		Task:             task,
	})
}
