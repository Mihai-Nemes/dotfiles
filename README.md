# dotfiles

Personal configuration files.

## Files

### `.rover`

A dotfile for the Rover project that stores **artifacts** and **skills**.

**Structure:**
- `project` – project name and description
- `artifacts` – list of project deliverables, build outputs, and assets
- `skills` – list of technologies and competencies used in the project

**Usage:**

Edit `.rover` to track your rover project artifacts and skills:

```yaml
artifacts:
  - name: rover-firmware
    type: firmware
    version: 1.0.0
    path: ./firmware
    description: Main firmware for the rover

skills:
  - name: Python
    level: intermediate
    category: programming
  - name: ROS
    level: beginner
    category: robotics
```
